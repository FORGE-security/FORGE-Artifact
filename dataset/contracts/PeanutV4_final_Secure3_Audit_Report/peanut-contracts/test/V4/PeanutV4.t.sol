// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/V4/PeanutV4.sol";
import "../../src/util/ERC20Mock.sol";
import "../../src/util/ERC721Mock.sol";
import "../../src/util/ERC1155Mock.sol";

contract PeanutV4Test is Test {
    PeanutV4 public peanutV4;
    ERC20Mock public testToken;
    ERC721Mock public testToken721;
    ERC1155Mock public testToken1155;

    // a dummy private/public keypair to test withdrawals
    address public constant PUBKEY20 = address(0xaBC5211D86a01c2dD50797ba7B5b32e3C1167F9f);
    bytes32 public constant PRIVKEY = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;

    function setUp() public {
        console.log("Setting up test");
        testToken = new ERC20Mock();
        testToken721 = new ERC721Mock();
        testToken1155 = new ERC1155Mock();
        peanutV4 = new PeanutV4(address(0));

        // Mint tokens for test accounts
        testToken.mint(address(this), 1000);
        testToken721.mint(address(this), 1);
        // testToken1155.mint(address(this), 1, 1000, "");

        // Approve PeanutV4 to spend tokens
        testToken.approve(address(peanutV4), 1000);
        testToken721.setApprovalForAll(address(peanutV4), true);
        // testToken1155.setApprovalForAll(address(peanutV4), true);
    }

    function testContractCreation() public {
        assertTrue(address(peanutV4) != address(0), "Contract creation failed");
    }

    function testMakeDepositERC20() public {
        uint256 amount = 100;

        // Moved minting and approval to the setup function
        uint256 depositIndex = peanutV4.makeDeposit(address(testToken), 1, amount, 0, PUBKEY20);

        assertEq(depositIndex, 0, "Deposit failed");
        assertEq(peanutV4.getDepositCount(), 1, "Deposit count mismatch");
    }

    // If we attempt to deposit ECO tokens as pure ERC20s (i.e. with _contractType = 1),
    // makeDeposit function must revert.
    function testECOMaliciousDeposit() public {
        // pretent that testToken is ECO
        PeanutV4 peanutV4ECO = new PeanutV4(address(testToken));

        // approve tokens to be spent by the new peanut instance
        testToken.approve(address(peanutV4), 1000);

        // Test!!!!!!!!
        vm.expectRevert("ECO DEPOSITS MUST USE _contractType 4");
        peanutV4ECO.makeDeposit(address(testToken), 1, 100, 0, address(0));
    }

    function testMakeDepositERC721() public {
        uint256 tokenId = 1;

        // Moved minting and approval to the setup function
        uint256 depositIndex = peanutV4.makeDeposit(address(testToken721), 2, 1, tokenId, PUBKEY20);

        assertEq(depositIndex, 0, "Deposit failed");
        assertEq(peanutV4.getDepositCount(), 1, "Deposit count mismatch");
    }

    // function testMakeDepositERC1155() public {
    //     uint256 tokenId = 1;
    //     uint256 amount = 100;

    //     // Moved minting and approval to the setup function
    //     uint256 depositIndex = peanutV4.makeDeposit(
    //         address(testToken1155),
    //         3,
    //         amount,
    //         tokenId,
    //         PUBKEY20
    //     );

    //     assertEq(depositIndex, 0, "Deposit failed");
    //     assertEq(peanutV4.getDepositCount(), 1, "Deposit count mismatch");
    // }

    // test sender withdrawal
    function testSenderTimeWithdraw() public {
        uint256 amount = 1000;

        assertEq(testToken.balanceOf(address(peanutV4)), 0, "Contract balance mismatch");
        // Moved minting and approval to the setup function
        uint256 depositIndex = peanutV4.makeDeposit(address(testToken), 1, amount, 0, PUBKEY20);

        assertEq(depositIndex, 0, "Deposit failed");
        assertEq(peanutV4.getDepositCount(), 1, "Deposit count mismatch");
        assertEq(testToken.balanceOf(address(peanutV4)), 1000, "Contract balance mismatch");

        // wait 25 hours
        vm.warp(block.timestamp + 25 hours);

        // Withdraw the deposit
        peanutV4.withdrawDepositSender(depositIndex);

        // Check that the contract has the correct balance
        assertEq(testToken.balanceOf(address(peanutV4)), 0, "Contract balance mismatch");
        assertEq(testToken.balanceOf(address(this)), 1000, "Sender balance mismatch");
    }
}
