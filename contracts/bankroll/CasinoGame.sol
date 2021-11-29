//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBankroll {
    function playFrom ( address player, uint256 amount ) external;
    function winTo ( address player, uint256 amount ) external;
}
contract CasinoGame is Context, Ownable {
    constructor(IBankroll Bankroll) {
        _setBankroll(Bankroll);
    }
    IBankroll _Bankroll;
    function setBankroll(IBankroll Bankroll) public onlyOwner {
        _setBankroll(Bankroll);
    }
    function _setBankroll(IBankroll Bankroll) private {
        _Bankroll = Bankroll;
    }
}