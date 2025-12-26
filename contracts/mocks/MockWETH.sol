// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MockERC20} from "./MockERC20.sol";
import "../interfaces/IWETH.sol";

contract MockWETH is MockERC20, IWETH {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor()
        MockERC20("Mock WETH", "WETH", 18)
      {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}