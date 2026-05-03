// SPDX-License-Identifier : MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig {
    configAdress public activeConfigAdress;

    constructor () {
        if (block.chainid == 11155111) {
            activeConfigAdress = EthSepoliaConfig();
        } else if (block.chainid == 1) {
            activeConfigAdress = EthMainnetConfig();
        } else {
            activeConfigAdress = EthAnvilConfig();
        }
    }

    struct configAdress {
        address priceFeed;
    }

    function EthSepoliaConfig () public pure returns (configAdress memory) {
        configAdress memory sepoliaAdress = configAdress({priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaAdress;
    }

    function EthMainnetConfig () public pure returns (configAdress memory) {
        configAdress memory ethMainnet = configAdress({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethMainnet;
    }

    function EthAnvilConfig () public pure returns (configAdress memory) {

    }
}