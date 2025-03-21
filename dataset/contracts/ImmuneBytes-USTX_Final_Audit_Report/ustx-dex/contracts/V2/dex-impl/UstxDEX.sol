// UstxDEXv2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUSTX.sol";
import "./IERC20.sol";
import "./Roles.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";


/// @title Up Stable Token eXperiment DEX
/// @author USTX Team
/// @dev This contract implements the DEX functionality for the USTX token (v2).
contract UstxDEX is Initializable {
	using Roles for Roles.Role;
	//SafeERC20 not needed for USDT(TRC20) and USTX(TRC20)
	using SafeERC20 for IERC20;

	/***********************************|
	|        Variables && Events        |
	|__________________________________*/

	//Constants
	uint256 private constant MAX_FEE = 200;   //maximum fee in BP (2%)
	uint256 private constant MAX_LAUNCH_FEE = 1000;  //maximum fee during launchpad (10%)

	//Variables
	uint256 private _decimals;			// 6
	uint256 private _feeBuy;			//buy fee in basis points
	uint256 private _feeSell;			//sell fee in basis points
	uint256 private _targetRatioExp;	//target reserve ratio for expansion in TH (1000s) to circulating cap
	uint256 private _targetRatioDamp;	//target reserve ratio for damping in TH (1000s) to circulating cap
	uint256 private _expFactor;			//expansion factor in TH
	uint256 private _dampFactor;		//damping factor in TH
	uint256 private _minExp;			//minimum expansion in TH
	uint256 private _maxDamp;			//maximum damping in TH
	uint256 private _collectedFees;		//amount of collected fees
	uint256 private _launchEnabled;		//launchpad mode if >=1
	uint256 private _launchTargetSize;	//number of tokens reserved for launchpad
	uint256 private _launchPrice;		//Launchpad price
	uint256 private _launchBought;		//number of tokens bought so far in Launchpad
	uint256 private _launchMaxLot;		//max number of usdtSold for a single operation during Launchpad
	uint256 private _launchFee;			//Launchpad fee
	address private _launchTeamAddr;	//Launchpad team address
	bool private _notEntered;			//reentrancyguard state
    bool private _paused;				//pausable state
	Roles.Role private _administrators;
	uint256 private _numAdmins;
	uint256 private _minAdmins;
	uint256 private _version;			//contract version

	uint256[5] _rtEnable;       //reserve token enable
	uint256[5] _rtTradeEnable;       //reserve token enable for trading
	uint256[5] _rtValue;     //reserve token value in TH (0-1000)
	uint256[5] _rtShift;       //reserve token decimal shift
    IERC20[5] _rt;    //reserve token address (element 0 is USDT)

	IUSTX _token;	// address of USTX token

	// Events
	event TokenBuy(address indexed buyer, uint256 indexed usdtSold, uint256 indexed tokensBought, uint256 price, uint256 tIndex);
	event TokenSell(address indexed buyer, uint256 indexed tokensSold, uint256 indexed usdtBought, uint256 price, uint256 tIndex);
	event Snapshot(address indexed operator, uint256 indexed reserveBalance, uint256 indexed tokenBalance);
    event Paused(address account);
	event Unpaused(address account);
	event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

	/**
	* @dev initialize function
	*
	*/
	function initialize() public initializer onlyAdmin {
		_launchTeamAddr = _msgSender();
		_decimals = 6;
		_feeBuy = 0;                    //0%
		_feeSell = 100;                 //1%
		_targetRatioExp = 240;          //24%
		_targetRatioDamp = 260;         //26%
		_expFactor = 1000;              //1
		_dampFactor = 1000;             //1
		_minExp = 100;                  //0.1
		_maxDamp = 100;                 //0.1
		_collectedFees = 0;
		_launchEnabled = 0;
		_notEntered = true;
		_paused = false;
		_numAdmins=0;
		_addAdmin(_msgSender());		//default admin
		_minAdmins = 2;					//at least 2 admins in charge
		_version = 1;

		uint256 j;						//initialize reserve variables
		for (j=0; j<5; j++) {
			_rtEnable[j]=0;
			_rtTradeEnable[j]=0;
		}
	}

	/**
	* @dev upgrade function for V2
	*/
	//function upgradeToV2() public onlyAdmin {
    //    require(_version<2,"Contract already up to date");
    //    _version=2;
	//		DO THINGS
    //}

	/***********************************|
	|        AdminRole                  |
	|__________________________________*/

	modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _administrators.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        require(_numAdmins>_minAdmins, "There must always be a minimum number of admins in charge");
        _removeAdmin(_msgSender());
    }

    function _addAdmin(address account) internal {
        _administrators.add(account);
        _numAdmins++;
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _administrators.remove(account);
        _numAdmins--;
        emit AdminRemoved(account);
    }

	/***********************************|
	|        Pausable                   |
	|__________________________________*/

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

	/***********************************|
	|        ReentrancyGuard            |
	|__________________________________*/

	/**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

	/***********************************|
	|        Context                    |
	|__________________________________*/

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

	/***********************************|
	|        Exchange Functions         |
	|__________________________________*/

	/**
	* @dev Public function to preview token purchase with exact input in USDT
	* @param usdtSold amount of USDT to sell
	* @return number of tokens that can be purchased with input usdtSold
	*/
	function buyTokenInputPreview(uint256 usdtSold) public view returns (uint256) {
		require(usdtSold > 0, "USDT sold must greater than 0");
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();

		(uint256 tokensBought,,) = _getBoughtMinted(usdtSold,tokenBalance,reserveBalance);

		return tokensBought;
	}

	/**
	* @dev Public function to preview token sale with exact input in tokens
	* @param tokensSold amount of token to sell
	* @return Amount of USDT that can be bought with input Tokens.
	*/
	function sellTokenInputPreview(uint256 tokensSold) public view returns (uint256) {
		require(tokensSold > 0, "Tokens sold must greater than 0");
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();

		(uint256 usdtsBought,,) = _getBoughtBurned(tokensSold,tokenBalance,reserveBalance);

		return usdtsBought;
	}

	/**
	* @dev Public function to buy tokens during launchpad
	* @param rSell amount of UDST to sell
	* @param minTokens minimum amount of tokens to buy
	* @return number of tokens bought
	*/
	function  buyTokenLaunchInput(uint256 rSell, uint256 tIndex, uint256 minTokens)  public whenNotPaused returns (uint256)  {
		require(_launchEnabled>0,"Function allowed only during launchpad");
		require(_launchBought<_launchTargetSize,"Launchpad target reached!");
		require(rSell<=_launchMaxLot,"Order too big for Launchpad");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _buyLaunchpadInput(rSell, tIndex, minTokens, _msgSender(), _msgSender());
	}

	/**
	* @dev Public function to buy tokens during launchpad and transfer them to recipient
	* @param rSell amount of UDST to sell
	* @param minTokens minimum amount of tokens to buy
	* @param recipient recipient of the transaction
	* @return number of tokens bought
	*/
	function buyTokenLaunchTransferInput(uint256 rSell, uint256 tIndex, uint256 minTokens, address recipient) public whenNotPaused returns(uint256) {
		require(_launchEnabled>0,"Function allowed only during launchpad");
		require(recipient != address(this) && recipient != address(0),"Recipient cannot be DEX or address 0");
		require(_launchBought<_launchTargetSize,"Launchpad target reached!");
		require(rSell<=_launchMaxLot,"Order too big for Launchpad");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _buyLaunchpadInput(rSell, tIndex, minTokens, _msgSender(), recipient);
	}

	/**
	* @dev Public function to buy tokens
	* @param rSell amount of UDST to sell
	* @param minTokens minimum amount of tokens to buy
	* @param tIndex index of the reserve token to swap
	* @return number of tokens bought
	*/
	function  buyTokenInput(uint256 rSell, uint256 tIndex, uint256 minTokens)  public whenNotPaused returns (uint256)  {
		require(_launchEnabled==0,"Function not allowed during launchpad");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _buyStableInput(rSell, tIndex, minTokens, _msgSender(), _msgSender());
	}

	/**
	* @dev Public function to buy tokens and transfer them to recipient
	* @param rSell amount of UDST to sell
	* @param minTokens minimum amount of tokens to buy
	* @param tIndex index of the reserve token to swap
	* @param recipient recipient of the transaction
	* @return number of tokens bought
	*/
	function buyTokenTransferInput(uint256 rSell, uint256 tIndex, uint256 minTokens, address recipient) public whenNotPaused returns(uint256) {
		require(_launchEnabled==0,"Function not allowed during launchpad");
		require(recipient != address(this) && recipient != address(0),"Recipient cannot be DEX or address 0");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _buyStableInput(rSell, tIndex, minTokens, _msgSender(), recipient);
	}

	/**
	* @dev Public function to sell tokens
	* @param tokensSold number of tokens to sell
	* @param minUsdts minimum number of UDST to buy
	* @return number of USDTs bought
	*/
	function sellTokenInput(uint256 tokensSold, uint256 tIndex, uint256 minUsdts) public whenNotPaused returns (uint256) {
		require(_launchEnabled==0,"Function not allowed during launchpad");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _sellStableInput(tokensSold, tIndex, minUsdts, _msgSender(), _msgSender());
	}

	/**
	* @dev Public function to sell tokens and trasnfer USDT to recipient
	* @param tokensSold number of tokens to sell
	* @param minUsdts minimum number of UDST to buy
	* @param recipient recipient of the transaction
	* @return number of USDTs bought
	*/
	function sellTokenTransferInput(uint256 tokensSold, uint256 tIndex, uint256 minUsdts, address recipient) public whenNotPaused returns (uint256) {
		require(_launchEnabled==0,"Function not allowed during launchpad");
		require(recipient != address(this) && recipient != address(0),"Recipient cannot be DEX or address 0");
		require(tIndex<5, "INVALID_INDEX");
		require(_rtEnable[tIndex]>0 && _rtTradeEnable[tIndex]>0,"Token disabled");
		return _sellStableInput(tokensSold, tIndex, minUsdts, _msgSender(), recipient);
	}

	/**
	* @dev public function to setup the reserve after launchpad (onlyAdmin, whenPaused)
	* @param startPrice target price
	* @return new reserve value
	*/
	function setupReserve(uint256 startPrice) public onlyAdmin whenPaused returns (uint256) {
		require(startPrice>0,"Price cannot be 0");
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();

		uint256 newReserve = reserveBalance * (10**_decimals) / startPrice;
		uint256 temp;
		if (newReserve>tokenBalance) {
		    temp = newReserve - tokenBalance;
		    _token.mint(address(this),temp);
		} else {
		    temp = tokenBalance - newReserve;
		    _token.burn(temp);
		}
		return newReserve;
	}

	/**
	* @dev public function to swap 1:1 between reserve tokens (onlyAdmin)
	* @param amount, amount to swap (6 decimal places)
	* @param tIndexIn, index of token to sell
	* @param tIndexOut, index of token to buy
	* @return amount swapped
	*/
    function swapReserveTokens(uint256 amount, uint256 tIndexIn, uint256 tIndexOut) public onlyAdmin returns (uint256) {
        require(amount > 0,"Amount should be higher than 0");
        require(tIndexIn <5 && tIndexOut <5 && tIndexIn != tIndexOut,"Index out of bounds or equal");
		require(_rtEnable[tIndexIn]>0 && _rtEnable[tIndexOut]>0,"Tokens disabled");

        _swapReserveTokens(amount, tIndexIn, tIndexOut, _msgSender());

        return amount;
    }

	/**
	* @dev private function to swap 1:1 between reserve tokens (nonReentrant)
	* @param amount, amount to swap (6 decimal places)
	* @param tIndexIn, index of token to sell
	* @param tIndexOut, index of token to buy
	* @param buyer, recipient
	* @return amount swapped
	*/
    function _swapReserveTokens(uint256 amount, uint256 tIndexIn, uint256 tIndexOut, address buyer) private nonReentrant returns (uint256) {
 		if (tIndexIn==0) {
    		_rt[tIndexIn].transferFrom(buyer, address(this), amount*(10**_rtShift[tIndexIn]));
 		} else {
 		    _rt[tIndexIn].safeTransferFrom(buyer, address(this), amount*(10**_rtShift[tIndexIn]));
 		}

 		if (tIndexOut==0) {
    		_rt[tIndexOut].transfer(buyer, amount*(10**_rtShift[tIndexOut]));
 		} else {
 		    _rt[tIndexOut].safeTransfer(buyer, amount*(10**_rtShift[tIndexOut]));
 		}

 		return amount;
    }

	/**
	* @dev Private function to buy tokens with exact input in USDT
	*
	*/
	function _buyStableInput(uint256 usdtSold, uint256 tIndex, uint256 minTokens, address buyer, address recipient) private nonReentrant returns (uint256) {
		require(usdtSold > 0 && minTokens > 0,"USDT sold and min tokens should be higher than 0");
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();

		(uint256 tokensBought, uint256 minted, uint256 fee) = _getBoughtMinted(usdtSold,tokenBalance,reserveBalance);
		_collectedFees = _collectedFees + fee;
		fee = fee*(10**_rtShift[tIndex]);

		require(tokensBought >= minTokens, "Tokens bought lower than requested minimum amount");
		if (minted>0) {
			_token.mint(address(this),minted);
		}

		if (tIndex==0) {
    		_rt[tIndex].transferFrom(buyer, address(this), usdtSold*(10**_rtShift[tIndex]));
    		if (fee>0) {
    			_rt[tIndex].transfer(_launchTeamAddr,fee);                //transfer fees to team
    		}
		} else {
    		_rt[tIndex].safeTransferFrom(buyer, address(this), usdtSold*(10**_rtShift[tIndex]));
    		if (fee>0) {
    			_rt[tIndex].safeTransfer(_launchTeamAddr,fee);                //transfer fees to team
    		}
		}
		_token.transfer(address(recipient),tokensBought);

		tokenBalance = _token.balanceOf(address(this));                //update token reserve
		reserveBalance = getReserveBalance();                           //update usdt reserve
		uint256 newPrice = reserveBalance * (10**_decimals) / tokenBalance;          //calc new price
		emit TokenBuy(buyer, usdtSold, tokensBought, newPrice, tIndex);       //emit TokenBuy event
		emit Snapshot(buyer, reserveBalance, tokenBalance);              //emit Snapshot event

		return tokensBought;
	}

	/**
	* @dev Private function to buy tokens during launchpad with exact input in USDT
	*
	*/
	function _buyLaunchpadInput(uint256 usdtSold, uint256 tIndex, uint256 minTokens, address buyer, address recipient) private nonReentrant returns (uint256) {
		require(usdtSold > 0 && minTokens > 0, "USDT sold and min tokens should be higher than 0");

		uint256 tokensBought = usdtSold * (10**_decimals) / _launchPrice;
		uint256 fee = usdtSold * _launchFee * (10**_rtShift[tIndex]) / 10000;

		require(tokensBought >= minTokens, "Tokens bought lower than requested minimum amount");
		_launchBought = _launchBought + tokensBought;
		_token.mint(address(this),tokensBought);                     //mint new tokens

		if (tIndex==0) {
		    _rt[0].transferFrom(buyer, address(this), usdtSold * (10**_rtShift[tIndex]));     //add usdtSold to reserve
		    _rt[0].transfer(_launchTeamAddr,fee);                //transfer fees to team
		} else {
		    _rt[tIndex].safeTransferFrom(buyer, address(this), usdtSold * (10**_rtShift[tIndex]));     //add usdtSold to reserve
		    _rt[tIndex].safeTransfer(_launchTeamAddr,fee);                //transfer fees to team
		}
		_token.transfer(address(recipient),tokensBought);        //transfer tokens to recipient
		emit TokenBuy(buyer, usdtSold, tokensBought, _launchPrice, tIndex);
		emit Snapshot(buyer, getReserveBalance(), _token.balanceOf(address(this)));

		return tokensBought;
	}

	/**
	* @dev Private function to sell tokens with exact input in tokens
	*
	*/
	function _sellStableInput(uint256 tokensSold, uint256 tIndex, uint256 minUsdts, address buyer, address recipient) private nonReentrant returns (uint256) {
		require(tokensSold > 0 && minUsdts > 0, "Tokens sold and min USDT should be higher than 0");
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();

		(uint256 usdtsBought, uint256 burned, uint256 fee) = _getBoughtBurned(tokensSold,tokenBalance,reserveBalance);
		_collectedFees = _collectedFees + fee;
		fee = fee * (10**_rtShift[tIndex]);         //adjust for correct number of decimals

		require(usdtsBought >= minUsdts, "USDT bought lower than requested minimum amount");
	 	if (burned>0) {
	    	_token.burn(burned);
		}
		_token.transferFrom(buyer, address(this), tokensSold);       //transfer tokens to DEX

	    if (tIndex==0) {                                                //USDT no safeERC20
    		_rt[0].transfer(recipient,usdtsBought * (10**_rtShift[tIndex]));                  //transfer USDT to user
    		if (fee>0) {
    			_rt[0].transfer(_launchTeamAddr,fee);                //transfer fees to team
    		}
		} else {
		    _rt[tIndex].safeTransfer(recipient,usdtsBought * (10**_rtShift[tIndex]));                  //transfer USDT to user
    		if (fee>0) {
    			_rt[tIndex].safeTransfer(_launchTeamAddr,fee);                //transfer fees to team
    		}
		}

		tokenBalance = _token.balanceOf(address(this));                //update token reserve
		reserveBalance = getReserveBalance();                 //update usdt reserve
		uint256 newPrice = reserveBalance * (10**_decimals) / tokenBalance;   //calc new price
		emit TokenSell(buyer, tokensSold, usdtsBought, newPrice, tIndex);     //emit Token event
		emit Snapshot(buyer, reserveBalance, tokenBalance);              //emit Snapshot event

		return usdtsBought;
	}

	/**
	* @dev Private function to get expansion correction
	*
	*/
	function _getExp(uint256 tokenReserve, uint256 usdtReserve) private view returns (uint256,uint256) {
		uint256 tokenCirc = _token.totalSupply();        //total
		tokenCirc = tokenCirc - tokenReserve;
		uint256 price = getPrice();         //multiplied by 10**decimals
		uint256 cirCap = price * tokenCirc;      //multiplied by 10**decimals
		uint256 ratio = usdtReserve * 1000000000 / cirCap;
		uint256 exp = ratio * 1000 / _targetRatioExp;
		if (exp<1000) {
			exp=1000;
		}
		exp = exp - 1000;
		exp=exp * _expFactor / 1000;
		if (exp<_minExp) {
	    	exp=_minExp;
		}
		if (exp>1000) {
	    	exp = 1000;
		}
		return (exp,ratio);
	}

	/**
	* @dev Private function to get k exponential factor for expansion
	*
	*/
	function _getKXe(uint256 pool, uint256 trade, uint256 exp) private pure returns (uint256) {
		uint256 temp = 1000-exp;
		temp = trade * temp;
		temp = temp / 1000;
		temp = temp + pool;
		temp = temp * 1000000000;
		uint256 kexp = temp / pool;
		return kexp;
	}

	/**
	* @dev Private function to get k exponential factor for damping
	*
	*/
	function _getKXd(uint256 pool, uint256 trade, uint256 exp) private pure returns (uint256) {
		uint256 temp = 1000-exp;
		temp = trade * temp;
		temp = temp / 1000;
		temp = temp+ pool;
		uint256 kexp = pool * 1000000000 / temp;
		return kexp;
	}

	/**
	* @dev Private function to get amount of tokens bought and minted
	*
	*/
	function _getBoughtMinted(uint256 usdtSold, uint256 tokenReserve, uint256 usdtReserve) private view returns (uint256,uint256,uint256) {
		uint256 fees = usdtSold * _feeBuy / 10000;
		uint256 usdtSoldNet = usdtSold - fees;

		(uint256 exp,) = _getExp(tokenReserve,usdtReserve);

		uint256 kexp = _getKXe(usdtReserve,usdtSoldNet,exp);

		uint256 temp = tokenReserve * usdtReserve;       //k
		temp = temp * kexp;
		temp = temp * kexp;
		uint256 kn = temp / 1000000000000000000;                 //uint256 kn=tokenReserve.mul(usdtReserve).mul(kexp).mul(kexp).div(1000000);

		temp = tokenReserve * usdtReserve;               //k
		usdtReserve = usdtReserve + usdtSoldNet;          //uint256 usdtReserveNew= usdtReserve.add(usdtSoldNet);
		temp = temp / usdtReserve;                       //USTXamm
		uint256 tokensBought = tokenReserve -temp;      //out=tokenReserve-USTXamm

		temp=kn / usdtReserve;                           //USXTPool_n
		uint256 minted=temp + tokensBought - tokenReserve;

		return (tokensBought, minted, fees);
	}

	/**
	* @dev Private function to get damping correction
	*
	*/
	function _getDamp(uint256 tokenReserve, uint256 usdtReserve) private view returns (uint256,uint256) {
		uint256 tokenCirc = _token.totalSupply();        //total
		tokenCirc = tokenCirc - tokenReserve;
		uint256 price = getPrice();         //multiplied by 10**decimals
		uint256 cirCap = price * tokenCirc;      //multiplied by 10**decimals
		uint256 ratio = usdtReserve * 1000000000/ cirCap;  //in TH
		if (ratio>_targetRatioDamp) {
	    	ratio=_targetRatioDamp;
		}
		uint256 damp = _targetRatioDamp - ratio;
		damp = damp * _dampFactor / _targetRatioDamp;

		if (damp<_maxDamp) {
    		damp=_maxDamp;
		}
		if (damp>1000) {
	    	damp = 1000;
		}
		return (damp,ratio);
	}

	/**
	* @dev Private function to get number of USDT bought and tokens burned
	*
	*/
	function _getBoughtBurned(uint256 tokenSold, uint256 tokenReserve, uint256 usdtReserve) private view returns (uint256,uint256,uint256) {
		(uint256 damp,) = _getDamp(tokenReserve,usdtReserve);

		uint256 kexp = _getKXd(tokenReserve,tokenSold,damp);

		uint256 k = tokenReserve * usdtReserve;           //k
		uint256 temp = k * kexp;
		temp = temp * kexp;
		uint256 kn = temp / 1000000000000000000;             //uint256 kn=tokenReserve.mul(usdtReserve).mul(kexp).mul(kexp).div(1000000);

		tokenReserve = tokenReserve + tokenSold;             //USTXpool_n
		temp = k / tokenReserve;                             //USDamm
		uint256 usdtsBought = usdtReserve - temp;            //out
		usdtReserve = temp;

		temp = kn / usdtReserve;                             //USTXPool_n

		uint256 burned=tokenReserve - temp;

		temp = usdtsBought * _feeSell / 10000;       //fee
		usdtsBought = usdtsBought - temp;

		return (usdtsBought, burned, temp);
	}

	/**************************************|
	|     Getter and Setter Functions      |
	|_____________________________________*/

	/**
	* @dev Function to set Token address (only admin)
	* @param tokenAddress address of the traded token contract
	*/
	function setTokenAddr(address tokenAddress) public onlyAdmin {
	    require(tokenAddress != address(0), "INVALID_ADDRESS");
	    _token = IUSTX(tokenAddress);
	}

	/**
	* @dev Function to set reserve token address (only admin)
	* @param reserveAddress address of the reserve token contract
	* @param index token index in array 0-4
	* @param decimals number of decimals
	*/
	function setReserveTokenAddr(uint256 index, address reserveAddress, uint256 decimals) public onlyAdmin {
		require(reserveAddress != address(0), "INVALID_ADDRESS");
		require(index<5, "INVALID_INDEX");
		require(decimals>=6, "INVALID_DECIMALS");
		_rt[index] = IERC20(reserveAddress);
		_rtShift[index] = decimals-_decimals;
		_rtEnable[index] = 0;
		_rtTradeEnable[index] = 0;
		_rtValue[index] = 1000;
	}

	/**
	* @dev Function to enable reserve token (only admin)
	* @param index token index in array 0-4
	* @param enable 0-1
	*/
	function setReserveTokenEnable(uint256 index, uint256 enable) public onlyAdmin {
		require(index<5, "INVALID_INDEX");
		_rtEnable[index] = enable;
	}

	/**
	* @dev Function to enable reserve token trading (only admin)
	* @param index token index in array 0-4
	* @param enable 0-1
	*/
	function setReserveTokenTradeEnable(uint256 index, uint256 enable) public onlyAdmin {
		require(index<5, "INVALID_INDEX");
		_rtTradeEnable[index] = enable;
	}

	/**
	* @dev Function to set reserve token value, relative to 1USD (only admin)
	* @param index token index in array 0-4
	* @param value in TH (0-1000)
	*/
	function setReserveTokenValue(uint256 index, uint256 value) public onlyAdmin {
		require(index<5, "INVALID_INDEX");
		require(value<=1000, "Invalid value range");
		_rtValue[index] = value;
	}

	/**
	* @dev Function to set fees (only admin)
	* @param feeBuy fee for buy operations (in basis points)
	* @param feeSell fee for sell operations (in basis points)
	*/
	function setFees(uint256 feeBuy, uint256 feeSell) public onlyAdmin {
		require(feeBuy<=MAX_FEE && feeSell<=MAX_FEE,"Fees cannot be higher than MAX_FEE");
		_feeBuy=feeBuy;
		_feeSell=feeSell;
	}

	/**
	* @dev Function to get fees
	* @return buy and sell fees in basis points
	*
	*/
	function getFees() public view returns (uint256, uint256) {
    	return (_feeBuy, _feeSell);
	}

	/**
	* @dev Function to set target ratio level (only admin)
	* @param ratioExp target reserve ratio for expansion (in thousandths)
	* @param ratioDamp target reserve ratio for damping (in thousandths)
	*/
	function setTargetRatio(uint256 ratioExp, uint256 ratioDamp) public onlyAdmin {
	    require(ratioExp<=1000 && ratioExp>=10 && ratioDamp<=1000 && ratioDamp >=10,"Target ratio must be between 1% and 100%");
	    _targetRatioExp = ratioExp;         //in TH
	    _targetRatioDamp = ratioDamp;       //in TH
	}

	/**
	* @dev Function to get target ratio level
	* return ratioExp and ratioDamp in thousandths
	*
	*/
	function getTargetRatio() public view returns (uint256, uint256) {
    	return (_targetRatioExp, _targetRatioDamp);
	}

	/**
	* @dev Function to get currect reserve ratio level
	* return current ratio in thousandths
	*
	*/
	function getCurrentRatio() public view returns (uint256) {
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();
		uint256 tokenCirc = _token.totalSupply();        //total
		tokenCirc = tokenCirc - tokenBalance;
		uint256 price = getPrice();         //multiplied by 10**decimals
		uint256 cirCap = price * tokenCirc;      //multiplied by 10**decimals
		uint256 ratio = reserveBalance * 1000000000 / cirCap;  //in TH
		return ratio;
	}

	/**
	* @dev Function to set target expansion factors (only admin)
	* @param expF expansion factor (in thousandths)
	* @param minExp minimum expansion coefficient to use (in thousandths)
	*/
	function setExpFactors(uint256 expF, uint256 minExp) public onlyAdmin {
		require(expF<=10000 && minExp<=1000,"Expansion factor cannot be more than 1000% and the minimum expansion cannot be over 100%");
		_expFactor=expF;
		_minExp=minExp;
	}

	/**
	* @dev Function to get expansion factors
	* @return _expFactor and _minExp in thousandths
	*
	*/
	function getExpFactors() public view returns (uint256, uint256) {
		return (_expFactor,_minExp);
	}

	/**
	* @dev Function to set target damping factors (only admin)
	* @param dampF damping factor (in thousandths)
	* @param maxDamp maximum damping to use (in thousandths)
	*/
	function setDampFactors(uint256 dampF, uint256 maxDamp) public onlyAdmin {
		require(dampF<=1000 && maxDamp<=1000,"Damping factor cannot be more than 100% and the maximum damping be over 100%");
		_dampFactor=dampF;
		_maxDamp=maxDamp;
	}

	/**
	* @dev Function to get damping factors
	* @return _dampFactor and _maxDamp in thousandths
	*
	*/
	function getDampFactors() public view returns (uint256, uint256) {
		return (_dampFactor,_maxDamp);
	}

	/**
	* @dev Function to get current price
	* @return current price
	*
	*/
	function getPrice() public view returns (uint256) {
		if (_launchEnabled>0) {
	    	return (_launchPrice);
		}else {
			uint256 tokenBalance = _token.balanceOf(address(this));
			uint256 reserveBalance = getReserveBalance();
			return (reserveBalance * (10**_decimals) / tokenBalance);      //price with decimals
		}
	}

	/**
	* @dev Function to get address of the traded token contract
	* @return Address of token that is traded on this exchange
	*
	*/
	function getTokenAddress() public view returns (address) {
		return address(_token);
	}

	/**
	* @dev Function to get the address of the reserve token contract
	* @param index token index in array 0-4
	* @return Address of token, relative decimal shift, enable, gradeenable, value, balance
	*/
	function getReserveData(uint256 index) public view returns (address, uint256, uint256, uint256, uint256, uint256) {
		uint256 bal=_rt[index].balanceOf(address(this));
		return (address(_rt[index]), _rtShift[index], _rtEnable[index], _rtTradeEnable[index], _rtValue[index], bal);
	}

	/**
	* @dev Function to get total reserve balance
	* @return reserve balance
	*/
	function getReserveBalance() public view returns (uint256) {
		uint256 j=0;
		uint256 temp;
		uint256 reserve=0;
		for (j=0; j<5; j++) {
		    temp=0;
		    if (_rtEnable[j]>0) {
		        temp = _rt[j].balanceOf(address(this));
		        temp = temp * _rtValue[j] / 1000;
		        temp = temp / (10**_rtShift[j]);
		    }
		    reserve += temp;
		}
		return reserve;
	}

	/**
	* @dev Function to get current reserves balance
	* @return USD reserve, USTX reserve, USTX circulating, collected fees
	*/
	function getBalances() public view returns (uint256,uint256,uint256,uint256) {
		uint256 tokenBalance = _token.balanceOf(address(this));
		uint256 reserveBalance = getReserveBalance();
		uint256 tokenCirc = _token.totalSupply() - tokenBalance;
		return (reserveBalance,tokenBalance,tokenCirc,_collectedFees);
	}

	/**
	* @dev Function to get every reserve token balance
	* @return b0, b1, b2, b3, b4 balances
	*/
	function getEveryReserveBalance() public view returns (uint256,uint256,uint256,uint256,uint256) {
		uint256 j=0;
		uint256[5] memory b;

		for (j=0; j<5; j++) {
		    if (_rtEnable[j]>0) {
		        b[j] = _rt[j].balanceOf(address(this));
				b[j] = b[j] / (10**_rtShift[j]);
		    }
        }
		return (b[0], b[1], b[2], b[3], b[4]);
	}

	/**
	* @dev Function to enable launchpad (only admin)
	* @param price launchpad fixed price
	* @param target launchpad target USTX sale
	* @param maxLot launchpad maximum purchase size in USDT
	* @param fee launchpad fee for the dev team (in basis points)
	* @return true if launchpad is enabled
	*/
	function enableLaunchpad(uint256 price, uint256 target, uint256 maxLot, uint256 fee) public onlyAdmin returns (bool) {
		require(price>0 && target>0 && maxLot>0 && fee<=MAX_LAUNCH_FEE,"Price, target and max lotsize cannot be 0. Fee must be lower than MAX_LAUNCH_FEE");
		_launchPrice = price;       //in USDT units
		_launchTargetSize = target; //in USTX units
		_launchBought = 0;          //in USTX units
		_launchFee = fee;           //in bp
		_launchMaxLot = maxLot;     //in USDT units
		_launchEnabled = 1;
		return true;
	}

	/**
	* @dev Function to disable launchpad (only admin)
	*
	*
	*/
	function disableLaunchpad() public onlyAdmin {
		_launchEnabled = 0;
	}

	/**
	* @dev Function to get launchpad status (only admin)
	* @return enabled state, price, amount of tokens bought, target tokens, max ourschase lot, fee
	*
	*/
	function getLaunchpadStatus() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		return (_launchEnabled,_launchPrice,_launchBought,_launchTargetSize,_launchMaxLot,_launchFee);
	}

	/**
	* @dev Set team address (only admin)
	* @param team address for collecting fees
	*/
	function setTeamAddress(address team) public onlyAdmin {
		require(team != address(0) && team != address(this), "Invalid team address");
		_launchTeamAddr = team;
	}

}
