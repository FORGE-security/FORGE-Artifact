// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface NFTStakingLike {
  error NFTStaking_BadParamsLength();
  error NFTStaking_InvalidLockPeriod();
  error NFTStaking_InvalidPoolAddress();
  error NFTStaking_IsNotExpired();
  error NFTStaking_NFTAlreadyStaked();
  error NFTStaking_NFTNotStaked();
  error NFTStaking_NoNFTStaked();
  error NFTStaking_PoolAlreadyExist();
  error NFTStaking_PoolNotExist();
  error NFTStaking_Unauthorize();
  event LogAddPool(
    address indexed _caller,
    address indexed _nftAddress,
    uint32 _poolWeight,
    uint32 _minLockPeriod,
    uint32 _maxLockPeriod
  );
  event LogExtendLockPeriod(
    address indexed _staker,
    address indexed _nftAddress,
    uint256 _nftTokenId,
    uint256 _lockUntil
  );
  event LogSetStakeNFTToken(address indexed _caller, address indexed _nftAddress);
  event LogStakeNFT(address indexed _staker, address indexed _nftAddress, uint256 _nftTokenId, uint256 _lockUntil);
  event LogUnstakeNFT(address indexed _staker, address indexed _nftAddress, uint256 _nftTokenId);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function addPool(
    address _nftAddress,
    uint32 _poolWeight,
    uint32 _minLockPeriod,
    uint32 _maxLockPeriod
  ) external;

  function setPool(
    address _nftAddress,
    uint32 _poolWeight,
    uint32 _minLockPeriod,
    uint32 _maxLockPeriod
  ) external;

  function extendLockPeriod(
    address _nftAddress,
    uint256 _nftTokenId,
    uint256 _newLockUntil
  ) external;

  function initialize() external;

  function isPoolExist(address _nftAddress) external view returns (bool);

  function isStaked(
    address _nftAddress,
    address _user,
    uint256 _nftTokenId
  ) external view returns (bool);

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external pure returns (bytes4);

  function owner() external view returns (address);

  function poolInfo(address)
    external
    view
    returns (
      uint256 poolWeight,
      uint256 minLockPeriod,
      uint256 maxLockPeriod
    );

  function renounceOwnership() external;

  function stakeNFT(
    address _nftAddress,
    uint256 _nftTokenId,
    uint256 _lockUntil
  ) external;

  function transferOwnership(address newOwner) external;

  function unstakeNFT(address _nftAddress, uint256 _nftTokenId) external;

  function userHighestWeightNftAddress(address) external view returns (address);

  function userNFTInStakingPool(address, address) external view returns (uint256);

  function userStakingNFTLockUntil(bytes32) external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"NFTStaking_BadParamsLength","type":"error"},{"inputs":[],"name":"NFTStaking_InvalidLockPeriod","type":"error"},{"inputs":[],"name":"NFTStaking_InvalidPoolAddress","type":"error"},{"inputs":[],"name":"NFTStaking_IsNotExpired","type":"error"},{"inputs":[],"name":"NFTStaking_NFTAlreadyStaked","type":"error"},{"inputs":[],"name":"NFTStaking_NFTNotStaked","type":"error"},{"inputs":[],"name":"NFTStaking_NoNFTStaked","type":"error"},{"inputs":[],"name":"NFTStaking_PoolAlreadyExist","type":"error"},{"inputs":[],"name":"NFTStaking_PoolNotExist","type":"error"},{"inputs":[],"name":"NFTStaking_Unauthorize","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_caller","type":"address"},{"indexed":true,"internalType":"address","name":"_nftAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"_poolWeight","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_minLockPeriod","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_maxLockPeriod","type":"uint256"}],"name":"LogAddPool","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_staker","type":"address"},{"indexed":true,"internalType":"address","name":"_nftAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"_nftTokenId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_lockUntil","type":"uint256"}],"name":"LogExtendLockPeriod","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_caller","type":"address"},{"indexed":true,"internalType":"address","name":"_nftAddress","type":"address"}],"name":"LogSetStakeNFTToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_staker","type":"address"},{"indexed":true,"internalType":"address","name":"_nftAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"_nftTokenId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_lockUntil","type":"uint256"}],"name":"LogStakeNFT","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_staker","type":"address"},{"indexed":true,"internalType":"address","name":"_nftAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"_nftTokenId","type":"uint256"}],"name":"LogUnstakeNFT","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"},{"internalType":"uint256","name":"_poolWeight","type":"uint256"},{"internalType":"uint256","name":"_minLockPeriod","type":"uint256"},{"internalType":"uint256","name":"_maxLockPeriod","type":"uint256"}],"name":"addPool","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"},{"internalType":"uint256","name":"_nftTokenId","type":"uint256"},{"internalType":"uint256","name":"_newLockUntil","type":"uint256"}],"name":"extendLockPeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"}],"name":"isPoolExist","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"},{"internalType":"address","name":"_user","type":"address"},{"internalType":"uint256","name":"_nftTokenId","type":"uint256"}],"name":"isStaked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"poolInfo","outputs":[{"internalType":"bool","name":"isInit","type":"bool"},{"internalType":"uint256","name":"poolWeight","type":"uint256"},{"internalType":"uint256","name":"minLockPeriod","type":"uint256"},{"internalType":"uint256","name":"maxLockPeriod","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"},{"internalType":"uint256","name":"_nftTokenId","type":"uint256"},{"internalType":"uint256","name":"_lockUntil","type":"uint256"}],"name":"stakeNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_nftAddress","type":"address"},{"internalType":"uint256","name":"_nftTokenId","type":"uint256"}],"name":"unstakeNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userHighestWeightNftAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"userNFTInStakingPool","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"userStakingNFT","outputs":[{"internalType":"uint256","name":"lockUntil","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/
