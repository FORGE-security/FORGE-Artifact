// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BNBBank {
	using SafeMath for uint256;
	
    //For Test
	uint256 constant public INVEST_MIN_AMOUNT = 5e16;
	uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public feeWallet;
    address payable private marketingWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event ReInvest(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
    event FeeWalletUpdated(address indexed oldFeeWallet, address indexed newFeeWallet);
    event MarketingWalletUpdated(address indexed oldMarketingWallet, address indexed newMarketingWallet);

	constructor(address payable _feeWallet, address payable _marketingWallet) {
		require(!isContract(_feeWallet));
		feeWallet = _feeWallet;
        require(!isContract(_marketingWallet));
        marketingWallet = _marketingWallet;

        plans.push(Plan(20, 60));
        plans.push(Plan(40, 40));
        plans.push(Plan(60, 35));
		plans.push(Plan(80, 30));
		plans.push(Plan(100, 28));
	}

    receive() external payable {

  	}

	function invest(address referrer, uint8 plan) public payable {
		if (!started) {
			if (msg.sender == feeWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 5, "Invalid plan");
        
		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 feeAmount = fee.div(2);
        feeWallet.transfer(feeAmount);
        marketingWallet.transfer(fee.sub(feeAmount));

		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);

		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		} else {
            if(referralBonus > 0)
                totalRefBonus = totalRefBonus.add(referralBonus);
        }

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		payable(msg.sender).transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}

    function reinvest(uint8 plan) public {
        User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		} else {
            if(referralBonus > 0)
                totalRefBonus = totalRefBonus = referralBonus;
        }

		user.withdrawn = user.withdrawn.add(totalAmount);

        require(totalAmount >= INVEST_MIN_AMOUNT);
		uint256 fee = totalAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 feeAmount = fee.div(2);
        feeWallet.transfer(feeAmount);
        marketingWallet.transfer(fee.sub(feeAmount));

        emit FeePayed(msg.sender, fee);

		user.deposits.push(Deposit(plan, totalAmount, block.timestamp));
		totalInvested = totalInvested.add(totalAmount);
        user.checkpoint = block.timestamp;
		emit ReInvest(msg.sender, plan, totalAmount);
    }

	function canHarvest(address userAddress) public view returns(bool) {
         uint256 totalAmount = getUserDividends(userAddress);
		uint256 referralBonus = getUserReferralBonus(userAddress);

		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
		}
		return (totalAmount > 0);
    }

    function canReinvest(address userAddress) public view returns(bool) {
		uint256 totalAmount = getUserDividends(userAddress);
		uint256 referralBonus = getUserReferralBonus(userAddress);
		if (referralBonus > 0) 
			totalAmount = totalAmount.add(referralBonus);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount)
			totalAmount = contractBalance;

        return (totalAmount >= INVEST_MIN_AMOUNT);
    }

    function updateFeeWallet(address payable _feeWallet) external {
        require(msg.sender == feeWallet, 'Limited Permission');
        emit FeeWalletUpdated(feeWallet, _feeWallet);
        feeWallet = _feeWallet;
    }

    function updateMarketingWallet(address payable _marketingWallet) external {
        require(msg.sender == marketingWallet, 'Limited Permission');
        emit MarketingWalletUpdated(marketingWallet, _marketingWallet);
        marketingWallet = _marketingWallet;
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}
		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}