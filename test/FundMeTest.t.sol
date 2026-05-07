// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address user = makeAddr("user");
    uint256 public AMOUNT_USD = 0.1 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(user, 10 ether);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.owner(), msg.sender);
    }

    function testFundIsLessThanMinUSD () public {
        uint256 amount = 5 gwei;

        vm.expectRevert(FundMe.MinimumNotMet.selector);
        vm.prank(user);
        fundMe.fund{value: amount}();

        assertEq(fundMe.getAddressToAmountFunded(user), 0e18);
    }

    function testMsgSenderIsUser () public {
        uint256 amount = 1 ether;

        vm.prank(user);
        fundMe.fund{value: amount}();

        assertEq(fundMe.getFunder(0), user);
    }

    function testAddressToAmountFundedIsMsgValue () public {
        uint256 amount = 1 ether;

        vm.prank(user);
        fundMe.fund{value: amount}();

        assertEq(fundMe.getAddressToAmountFunded(user), amount);
    }

    function testWithdrawOwnerIsNotOwner () public {
        uint256 amount = 1 ether;

        vm.startPrank(user);
        fundMe.fund{value: amount}();

        vm.expectRevert(FundMe.NotOwner.selector);
        fundMe.withdraw();
        vm.stopPrank();

        assertTrue(fundMe.owner() != fundMe.getFunder(0));
    }

    function testFundersAndUserBalanceIsZero() public {
        uint160 totalFunders = 9;
        uint160 startAtIndex = 0;

        for (uint160 i = startAtIndex; i < totalFunders; i++){
            hoax(address(i), 10 ether);
            fundMe.fund{value: 1 ether}();
        }

        vm.prank(fundMe.owner());
        fundMe.withdraw();

        for (uint160 i = startAtIndex; i < totalFunders; i++){
            assertEq(fundMe.getAddressToAmountFunded(address(i)), 0);

            vm.expectRevert(FundMe.NoBalance.selector);
            vm.prank(address(i));
            fundMe.withdrawUser();

            vm.expectRevert();
            fundMe.getFunder(i);
        }
    }

        // 1. Test withdraw dengan 1 funder
    function testWithdrawWithASingleFunder() public {
        // Arrange (Menyiapkan kondisi)
        uint256 startingOwnerBalance = fundMe.owner().balance;
        
        vm.prank(user);
        fundMe.fund{value: 1 ether}();
        uint256 fundMeBalanceAfterFund = address(fundMe).balance;

        // Act (Melakukan aksi)
        vm.prank(fundMe.owner());
        fundMe.withdraw();

        // Assert (Memastikan hasil)
        uint256 endingOwnerBalance = fundMe.owner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + fundMeBalanceAfterFund, endingOwnerBalance);
    }

    // 2. Test withdraw dengan banyak funder (Multiple Funders)
    function testWithdrawWithMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), 10 ether);
            fundMe.fund{value: 1 ether}();
        }

        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.owner());
        fundMe.withdraw();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, fundMe.owner().balance);
    }

    // 3. Test fungsi withdrawUser (User menarik dananya sendiri)
    function testWithdrawUserSuccess() public {
        // Arrange
        vm.prank(user);
        fundMe.fund{value: 1 ether}();
        uint256 startingUserBalance = user.balance;

        // Act
        vm.prank(user);
        fundMe.withdrawUser();

        // Assert
        assertEq(fundMe.getAddressToAmountFunded(user), 0);
        assertEq(user.balance, startingUserBalance + 1 ether);
    }
}