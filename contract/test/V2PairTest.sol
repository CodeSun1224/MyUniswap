// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/V2Pair.sol";
import "../src/solmate/tokens/ERC20.sol";
import "../src/V2PairFactory.sol";

contract MyERC20 is ERC20{
    constructor (string memory _name, string memory _symbol, uint8 _decimals) 
        ERC20 (_name,_symbol,_decimals) 
    {}
        
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract V2PairTest is Test{
    MyERC20 token0;
    MyERC20 token1;
    V2Pair pair;

    function setUp() public {
        token0 = new MyERC20("token0", "T0", 18);
        token1 = new MyERC20("token1", "T1", 18);
        V2PairFactory factory = new V2PairFactory();
        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = V2Pair(pairAddress);
    }

    function testMint() public {
        token0.mint(address(this), 1 ether);
        token1.mint(address(this), 1 ether);

        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);
    }
}