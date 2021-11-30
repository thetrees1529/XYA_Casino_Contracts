//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "luk1529_solidity/contracts/utils/Random.sol";

contract CardGame is Random("cardywardy") {

    constructor() {
        for(uint i; i <= uint(Suit.SPADES); i ++) {
            for(uint j; j <= uint(Value.KING); j ++) {
                _referenceDeck.push(Card(Suit(i), Value(j)));
            }
        }
    }

    enum Value {
        ACE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT,
        NINE,
        TEN,
        JACK,
        QUEEN,
        KING
    }

    enum Suit {
        CLUBS,
        DIAMONDS,
        HEARTS,
        SPADES
    }

    struct Card {
        Suit suit;
        Value value;
    }

    Card[] _referenceDeck;

    function _copyReferenceDeck(uint deckId) internal {
        _decks[deckId] = _referenceDeck;
    }
    function _getDeck(uint deckId) internal view returns(Card[] storage) {
        return _decks[deckId];
    }
    function _pickCardFromDeck(uint deckId, uint index) internal returns(Card storage pickedCard) {
        Card[] storage deck = _getDeck(deckId);
        pickedCard = deck[index];
        for(uint i = index + 1; i < deck.length; i ++) {
            deck[i - 1] = deck[i];
        }
        deck.pop();
    }

    mapping(uint => Card[]) _decks;




}