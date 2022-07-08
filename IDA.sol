// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IDA is ERC20{
    uint256 public decimal = 10 ** 18;
    uint256 public MaxSupply = 100000000 * decimal; // Max Supply limit 
    constructor(string memory _name, string memory _symbol) ERC20(_name,_symbol){}
    /*
        Anyone can come and mint using mint() function it also need to passed a amount of token users wantes to mint
        ex: mint(20) it mint 20 tokens 
        NOTE: user can not Mint more then Max supply
    */
    function mint(uint256 amount) external { 
        uint256 checkSupply = totalSupply() + (amount * decimal);
        require( checkSupply <= MaxSupply, "All the tokens are already minted");
        _mint(msg.sender,amount * decimal);
    }

    /*
        Anyone can come and burn using burn() function it also need to passed a amount of token users wantes to burn
        ex: burn(20) it burn 20 tokens 
        NOTE: user can not burn more then Total supply
    */
    function burn(uint256 amount) external {
        uint256 checkSupply = totalSupply() - (amount * decimal);
        require(checkSupply >= 0,"trying to burn more then totalsupply");
        _burn(msg.sender,amount * decimal);
    }
}