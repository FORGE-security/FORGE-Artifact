// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnableContract.sol";
import "./IBaseDoNFT.sol";

abstract contract BaseDoNFT is OwnableContract,ReentrancyGuard,ERC721Enumerable,IBaseDoNFT {
    using EnumerableSet for EnumerableSet.UintSet;
    address internal oNftAddress;
    uint256 public curDoid;
    uint256 public curDurationId;
    uint64 private maxDuration = 31526000;
    mapping(uint256 => DoNftInfo) internal doNftMapping;
    mapping(uint256 => Duration) internal durationMapping;
    mapping(uint256 => uint256) internal oid2xid;
    mapping(uint256 => address) internal checkInUserMapping;

    bool private isOnlyNow = true;
    string private _doName;
    string private _doSymbol;
    string private _dclURI;
    
    constructor()ERC721("DoNFT","DoNFT"){
        initOwnableContract();
    }

    modifier onlyNow(uint64 start) {
        if(isOnlyNow){
            require(start <= block.timestamp, "must from now");
        }
        _;
    }

    function onlyApprovedOrOwner(address spender,address nftAddress,uint256 tokenId) internal view returns(bool){
        address owner = ERC721(nftAddress).ownerOf(tokenId);
        require(owner != address(0),"ERC721: operator query for nonexistent token");
        return (spender == owner || ERC721(nftAddress).getApproved(tokenId) == spender || ERC721(nftAddress).isApprovedForAll(owner, spender));
    }

    function init(address address_,string memory name_, string memory symbol_) public {
        require(oNftAddress==address(0),"already inited");
        oNftAddress = address_;
        _doName = name_;
        _doSymbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _doName;
    }
    function symbol() public view virtual override returns (string memory) {
        return _doSymbol;
    }

    function setIsOnlyNow(bool v) public onlyAdmin {
        isOnlyNow = v;
    }

    function contains(uint256 tokenId,uint256 durationId) public view returns(bool){
        return doNftMapping[tokenId].durationList.contains(durationId);
    }

    function getDurationIdList(uint256 tokenId) external view returns(uint256[] memory){
        DoNftInfo storage info = doNftMapping[tokenId];
        return info.durationList.values();
    }
    function getDuration(uint256 durationId) public view returns(uint64, uint64){
        Duration storage duration = durationMapping[durationId];
        return (duration.start,duration.end);
    }

    function getDurationByIndex(uint256 tokenId,uint256 index) public view returns(uint256 durationId,uint64 start, uint64 end){
        DoNftInfo storage info = doNftMapping[tokenId];
        require(index < info.durationList.length(),"out of range");
        durationId = info.durationList.at(index);
        (start,end) = getDuration(durationId);
        return(durationId,start,end);
    }

    function isValidNow(uint256 tokenId) public view returns(bool isValid){
        DoNftInfo storage info = doNftMapping[tokenId];
        uint256 length = info.durationList.length();
        uint256 durationId;
        for (uint256 index = 0; index < length; index++) {
            durationId = info.durationList.at(index);
            if(durationMapping[durationId].start <= block.timestamp && block.timestamp <= durationMapping[durationId].end){
                return true;
            }
        }
        return false;
    }

    function getDurationListLength(uint256 tokenId) external view returns(uint256){
        return doNftMapping[tokenId].durationList.length();
    }

    function getDoNftInfo(uint256 tokenId) public view returns(uint256 oid, uint256[] memory durationIds, uint64[] memory starts,uint64[] memory ends,uint64 nonce){
        DoNftInfo storage info = doNftMapping[tokenId];
        oid = info.oid;
        nonce = info.nonce;
        uint256 length = info.durationList.length();
        uint256 durationId;
        starts = new uint64[](length);
        ends = new uint64[](length);
        durationIds = info.durationList.values();
        for (uint256 index = 0; index < length; index++) {
            durationId = info.durationList.at(index);
            starts[index] = durationMapping[durationId].start;
            ends[index] = durationMapping[durationId].end;
        }
        
    }

    function getNonce(uint256 tokenId) external view returns(uint64){
       return doNftMapping[tokenId].nonce;
    }

    function mint(
        uint256 tokenId,
        uint256 durationId,
        uint64 start,
        uint64 end,
        address to
    ) public onlyNow(start) nonReentrant returns(uint256 tid){
        if(start < block.timestamp){
            start = uint64(block.timestamp);
        }
        require(_isApprovedOrOwner(_msgSender(), tokenId) || _isApprovedOrOwner(tx.origin, tokenId), "not owner nor approved");
        require(end > start && end <= block.timestamp + maxDuration, "invalid start or end");
        DoNftInfo storage info = doNftMapping[tokenId];
        require(contains(tokenId,durationId), "not contains durationId");
        Duration storage duration = durationMapping[durationId];
        require(start >= duration.start && end <= duration.end, "invalid duration");
        uint256 tDurationId;
        if (start == duration.start && end == duration.end) {
            tid = mintDoNft(to,info.oid,start,end);
            tDurationId = curDurationId;
            _burnDuration(tokenId, durationId);
            if(info.durationList.length() == 0){
                _burn(tokenId);
            }
        } else {
            if (start > block.timestamp && start > duration.start + 1) {
                newDuration(tokenId, duration.start, start-1);
            }
            if (duration.end > end + 1) {
                duration.start = end + 1;
            }else{
                duration.end = start - 1;
            }

            tid = mintDoNft(to, info.oid,start,end);
            tDurationId = curDurationId;
        }
        
        if(start==block.timestamp){
            checkIn(to, tid, tDurationId);
        }
        emit MetadataUpdate(tokenId);
        
    }
    
    function setMaxDuration(uint64 v) public onlyAdmin{
        maxDuration = v;
    }
    function newDoNft(uint256 oid_,uint64 start,uint64 end) internal returns (uint256)
    {
        curDoid++;
        DoNftInfo storage info = doNftMapping[curDoid];
        info.oid = oid_;
        info.nonce = 0;
        newDuration(curDoid,start,end);
        return curDoid;
    }
    
    function newDuration(uint256 tokenId,uint64 start,uint64 end) private{
        curDurationId++;
        durationMapping[curDurationId] = Duration(start,end);
        doNftMapping[tokenId].durationList.add(curDurationId);
        emit DurationUpdate(curDurationId,tokenId,start,end);
    }

    function mintDoNft(address to, uint256 oid_,uint64 start,uint64 end)
        internal
        returns (uint256)
    {
        newDoNft(oid_,start,end);
        _safeMint(to, curDoid);
        return curDoid;
    }

    function concat(uint256 tokenId,uint256 durationId,uint256 targetTokenId,uint256 targetDurationId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(contains(tokenId,durationId),"not contains");
        require(ownerOf(tokenId) == ownerOf(targetTokenId), "diff owner");
        require(doNftMapping[tokenId].oid == doNftMapping[targetTokenId].oid , "diff oid");
        require(contains(targetTokenId,targetDurationId),"not contains");
        
        Duration storage duration = durationMapping[durationId];
        Duration storage targetDuration = durationMapping[targetDurationId];
        if(duration.end < targetDuration.start){
            require(duration.end+1==targetDuration.start);
            targetDuration.start = duration.start;
            _burnDuration(tokenId,durationId);
        }
        else if(targetDuration.end < duration.start){
            require(targetDuration.end+1 == duration.start);
            targetDuration.end = duration.end;
            _burnDuration(tokenId,durationId);
        }
    }

    function _burnDuration(uint256 tokenId,uint256 durationId) private{
        delete durationMapping[durationId];
        doNftMapping[tokenId].durationList.remove(durationId);
        uint256[] memory arr = new uint256[](1);
        arr[0] = durationId;
        emit DurationBurn(arr);
    }
   
    function _burnXNft(uint256 wid) internal {
        DoNftInfo storage info = doNftMapping[wid];
        uint256 length = info.durationList.length();
        for (uint256 index = 0; index < length; index++) {
            delete durationMapping[info.durationList.at(index)];
        }
        emit DurationBurn(info.durationList.values());
        delete info.durationList;
        delete oid2xid[info.oid];
        _burn(wid);
    }

    function _burn(uint256 tokenId) internal override virtual {
        ERC721._burn(tokenId);
        delete doNftMapping[tokenId];
    }

    function checkIn(address to,uint256 tokenId,uint256 durationId) public virtual{
        require(_isApprovedOrOwner(_msgSender(), tokenId) || _isApprovedOrOwner(tx.origin, tokenId), "not owner nor approved");
        DoNftInfo storage info = doNftMapping[tokenId];
        Duration storage duration = durationMapping[durationId];
        require(duration.end >= block.timestamp,"invalid end");
        require(duration.start <= block.timestamp,"invalid start");
        require(info.durationList.contains(durationId),"not contains");
        checkInUserMapping[info.oid] = to;
        emit CheckIn(tx.origin,to,tokenId,durationId);
    }

    function getUser(uint256 originalNftId) public view returns(address){
        return checkInUserMapping[originalNftId];
    }

    function gc(uint256 tokenId,uint256[] calldata durationIds) public {
        DoNftInfo storage info = doNftMapping[tokenId];
        uint256 durationId;
        Duration storage duration;
        for (uint256 index = 0; index < durationIds.length; index++) {
            durationId = durationIds[index];
            if(contains(tokenId, durationId)){
                duration = durationMapping[durationId];
                if(duration.end <= block.timestamp){
                    _burnDuration(tokenId,durationId);
                }
            }
        }
        
        if(info.durationList.length() == 0){
            require(!isXNft(tokenId),"can not burn xNFT");
            _burn(tokenId);
        }
    }

    function getFingerprint(uint256 tokenId) public view returns(bytes32 print){
        (uint256 oid, uint256[] memory durationIds,uint64[] memory starts,uint64[] memory ends,uint64 nonce) = getDoNftInfo(tokenId);
        print = keccak256(abi.encodePacked(oid,durationIds,starts,ends,nonce));
    }

    function isXNft(uint256 tokenId) public view returns(bool) {
        if(tokenId == 0) return false;
        
        return oid2xid[doNftMapping[tokenId].oid] == tokenId ;
    }

    function isWrap() public pure virtual returns(bool){
        return false;
    }

    function getOriginalNftAddress() external view returns(address){
        return oNftAddress;
    }
    function getOriginalNftId(uint256 tokenId) external view returns(uint256){
        DoNftInfo storage info = doNftMapping[tokenId];
        return info.oid;
    }

    function getXNftId(uint256 originalNftId) public view returns(uint256) {
        return oid2xid[originalNftId] ;
    }

    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data
    ) external override virtual pure returns (bytes4) {
        bytes4 received = 0x150b7a02;
        return received;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        doNftMapping[tokenId].nonce++;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IBaseDoNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) public onlyAdmin {
        _dclURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(_dclURI, Strings.toString(tokenId)));
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    
}
