// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../test/MyERC20.sol";
import "../src/V2PairFactory.sol";
import "../src/V2Router.sol";
import "../src/V2Pair.sol";

contract DeployDevelopment is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyERC20 token0 = new MyERC20("token0", "T0", 18);
        MyERC20 token1 = new MyERC20("token1", "T1", 18);
        V2PairFactory factory = new V2PairFactory();
        V2Router router = new V2Router(address(factory));
        address pairAddress = factory.createPair(address(token0), address(token1));
        V2Pair pair = V2Pair(pairAddress);
        token0.mint(msg.sender, 10 ether);
        token1.mint(msg.sender, 10 ether);
        vm.stopBroadcast();
        console.log("token0 address: ", address(token0));
        console.log("token1 address: ", address(token1));
        console.log("factory address: ", address(factory));
        console.log("router address: ", address(router));
        console.log("token0/token1 address: ", address(pair));
    }
}
