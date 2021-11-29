//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBankroll {
    function playFrom ( address player, uint256 amount ) external;
    function winTo ( address player, uint256 amount ) external;
}
contract CasinoGame{
    constructor(IBankroll Bankroll) {
        _setBankroll(Bankroll);
    }
    IBankroll _Bankroll;
    function _setBankroll(IBankroll Bankroll) internal {
        _Bankroll = Bankroll;
    }
    function _getBankroll() internal view returns(IBankroll) {
        return _Bankroll;
    }
}