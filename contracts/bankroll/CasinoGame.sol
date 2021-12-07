//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Bankroll.sol";
contract CasinoGame{
    constructor(Bankroll Bankroll_) {
        _setBankroll(Bankroll_);
    }
    Bankroll _Bankroll;
    function _setBankroll(Bankroll Bankroll_) internal {
        _Bankroll = Bankroll_;
    }
    function _getBankroll() internal view returns(Bankroll) {
        return _Bankroll;
    }
}