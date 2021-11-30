//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./card/CardGame.sol";

contract Blackjack is CardGame {
    struct Player {
        address addr;
        Card[] hand;
    }
    
}