// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/V2Pair.sol";
import "../src/solmate/tokens/ERC20.sol";
import "../src/V2PairFactory.sol";
import "../test/MyERC20.sol";

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
        token0.mint(address(this), 10 ether);
        token1.mint(address(this), 10 ether);
    }

    function testTokenAddress() public view {
        // createPair要对token地址的大小排序
        assert(address(token0) > address(token1));
    }

    function testMint() public {
        // 首次添加
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);
        assertReserves(1 ether, 1 ether);
        assertEq(token0.balanceOf(address(this)), 9 ether);
        assertEq(token1.balanceOf(address(this)), 9 ether);

        // 按比例添加
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000); // 1 ether - 1000 + 1 ether
        assertEq(pair.totalSupply(), 2 ether); // 1 ether + 1 ether
        assertReserves(2 ether, 2 ether); // 1 + 1 ， 1 + 1

        // 不按比例添加，取最小的，算出的流动性还是1 ether
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 3 ether - 1000); // 1 ether - 1000 + 1 ether + 1 ether
        assertEq(pair.totalSupply(), 3 ether); // 1 + 1 + 1
        assertReserves(3 ether, 4 ether); // 2 + 2 ， 2 + 1
    }

    function testBurn() public {
        // 首次添加
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));
        /// LP Token的总数为1000
        assertEq(pair.totalSupply(), 1000);
        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1000, 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testSwapZeroOut() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert("InsufficientOutputAmount");
        pair.swap(0, 0, address(this), "");
    }

    function testSwapBidirectional() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.18 ether, 0.09 ether, address(this), "");

        /// this总共10 ether，给了pair 1 ether，之后又给了0.1 ether， swap后又转给this 0.09 ether
        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.01 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether - 0.02 ether,
            "unexpected token1 balance"
        );
        /// swap的最后更新reserve0, reserve1
        assertReserves(2 ether + 0.02 ether, 1 ether + 0.01 ether);
    }

    function testFirstMintSmall() public {
        token0.transfer(address(pair), 1 );
        token1.transfer(address(pair), 1 );
        /// 要加在mint前面
        vm.expectRevert(stdError.arithmeticError);
        pair.mint(address(this));
    }

    function assertReserves(uint112 reserve0_, uint112 reserve1_) internal {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(reserve0, reserve0_);
        assertEq(reserve1, reserve1_);
    }
}