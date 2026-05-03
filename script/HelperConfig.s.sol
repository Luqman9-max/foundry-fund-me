// SPDX-License-Identifier : MIT
pragma solidity ^0.8.18;

import {script} from "forge-std/Script.sol";

contract HelperConfig {
    configAdress public activeConfigAdress;

    constructor () {
        if (block.chainid == 11155111) {
            activeConfigAdress = EthSepoliaConfig();
        } else {
            activeConfigAdress = EthAnvilConfig();
        }
    }

    struct configAdress {
        address priceFeed;
    }

    function EthSepoliaConfig () public pure returns (configAdress) {
        configAdress sepoliaAdress = configAdress({priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaAdress;
    }

    function EthAnvilConfig () public pure returns (configAdress) {

    }
}