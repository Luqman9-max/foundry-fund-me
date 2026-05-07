// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    /*//////////////////////////////////////////////////////////////
                        CUSTOM ERRORS (WITH PARAMS)
    //////////////////////////////////////////////////////////////*/
    error NotOwner();
    error MinimumNotMet();
    error NoBalance();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                EVENTS (INDEXED)
    //////////////////////////////////////////////////////////////*/
    event Funded(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OwnerWithdraw(address indexed owner, uint256 totalAmount);

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MIN_USD = 5e18;

    address public immutable owner;
    address[] private funders;
    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private addressToAmountFunded;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address priceFeed) {
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier hasBalance() {
        if (addressToAmountFunded[msg.sender] == 0) {
            revert NoBalance();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                FUND
    //////////////////////////////////////////////////////////////*/
    function fund() external payable {
        uint256 usdValue = msg.value.getConversionRate(s_priceFeed);

        if (usdValue < MIN_USD) {
            revert MinimumNotMet();
        }

        if (addressToAmountFunded[msg.sender] == 0) {
            funders.push(msg.sender);
        }

        addressToAmountFunded[msg.sender] += msg.value;

        emit Funded(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER WITHDRAW
    //////////////////////////////////////////////////////////////*/
    function withdraw() external onlyOwner {
        address[] memory mFunders = funders;
        uint256 length = mFunders.length;

        for (uint256 i = 0; i < length; i++) {
            address funder = mFunders[i];
            addressToAmountFunded[funder] = 0;
        }

        delete funders;

        uint256 balance = address(this).balance;

        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) revert TransferFailed();

        emit OwnerWithdraw(owner, balance);
    }

    /*//////////////////////////////////////////////////////////////
                        USER WITHDRAW (PULL)
    //////////////////////////////////////////////////////////////*/
    function withdrawUser() external hasBalance {
        uint256 amount = addressToAmountFunded[msg.sender];

        addressToAmountFunded[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getFunder(uint256 index) external view returns (address) {
        return funders[index];
    }

    function getAddressToAmountFunded(address user) external view returns (uint256) {
        return addressToAmountFunded[user];
    }

    function getVersion () public view returns (uint256) {
        return s_priceFeed.version();
    }
}
