//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "luk1529_solidity/contracts/utils/Random.sol";

contract Slots is Ownable, Random {
    using Address for address;

    constructor(IERC20 _XYA) {
        XYA = _XYA;
    }
    
    
    
    //XYA
    IERC20 XYA;
    
    
    
    //machine
    string[][3] _reels;
    uint _creditPrice;
    uint _nudgesChance; uint _holdsChance; /* percentage chance to receive nudges and holds */
    uint _nudgesMin; uint _nudgesMax; /* minimum and maximum nudges given */
    uint _holdsMin; uint _holdsMax; /* minimum and maximum holds given */
    
    
    
    //events
    event Won(address indexed player, uint winnings);
    event Spun(address indexed player);
    event Deposit(address indexed player, uint amount);
    event Withdraw(address indexed player, uint amount);
    
    
    
    //player info
    mapping(address => uint[3]) _positions;
    mapping(address => bool[3]) _held;
    mapping(address => uint) _holds;
    mapping(address => uint) _nudges;
    mapping(address => uint) _credits;
    mapping(address => uint) _bank;
    mapping(address => string[3][]) _historicalResults;
    mapping(address => uint[]) _historicalWinnings;
    


    //payout info
    struct PayLineData {
        string[3] payLine;
        uint payout;
    }
    PayLineData[] _payTable;



    //pay table
    function addToPayTable(PayLineData calldata _payLineData) public onlyOwner {
        _addToPayTable(_payLineData);
    }

    function removeFromPayTable(uint _index) public onlyOwner {
        _removeFromPayTable(_payTable, _index);
    }

    function getPayTableLength() public view returns(uint) {
        return _getPayTableLength();
    }

    function getPayLineData(uint _index) public view returns(PayLineData memory) {
        return _getPayLineData(_index);
    }



    //holds and nudges
    function holdsInfo() public view returns(uint chance, uint min, uint max) {
        return _getHoldsInfo();
    }

    function nudgesInfo() public view returns(uint chance, uint min, uint max) {
        return _getNudgesInfo();
    }

    function setHoldsInfo(uint _chance, uint _min, uint _max) public onlyOwner {
        _setHoldsInfo(_chance, _min, _max);
    }

    function setnudgesInfo(uint _chance, uint _min, uint _max) public onlyOwner {
        _setNudgesInfo(_chance, _min, _max);
    }



    //previous results
    function getHistoricalResultsLengthOfPlayer(address _player) public view returns(uint) {
        return _getHistoricalResultsLength(_player);
    }

    function getHistoricalResultOfPlayerByIndex(address _player, uint _index) public view returns(string[3] memory) {
        return _getHistoricalResult(_player, _index);
    }

    function getHistoricalWinningsLengthOfPlayer(address _player) public view returns(uint) {
        return _getHistoricalResultsLength(_player);
    }

    function getHistoricalWinningOfPlayerbyIndex(address _player, uint _index) public view returns(uint) {
        return _getHistoricalWinning(_player, _index);
    }



    //reel data
    function reels() public view returns(string[][3] memory ) {
        return _getReels();
    }

    function setReels(string[][3] calldata _newReels) public onlyOwner {
        _setReels(_newReels);
    }

    function positionsOf(address _player) public view returns(uint[3] memory) {
        return _getPositions(_player);
    }

    //admin withdraw
    function withdraw(uint _value) public onlyOwner {
        _withdraw(_msgSender(), _value);
    }



    //price per spin
    function creditPrice() public view returns(uint) {
        return _getCreditPrice();
    }

    function setCreditPrice(uint _price) public onlyOwner {
        _setCreditPrice(_price);
    }



    //main game
    function deposit(uint _value) public {
        address player = _msgSender();
        XYA.transferFrom(player, address(this), _value);
        _addToCredits(player, _value);
    }

    function withdrawBank() public {
        address player = _msgSender();
        uint bank = _getBank(player);
        XYA.transfer(player, bank);
        _takeFromBank(player, bank);
    }

    function spin() public noContract {
        address player = _msgSender();
        _payForSpin(player);
        _spin(player);
        _payout(player);
        _clearNudges(player);
        _clearHolds(player);
        _resetHeld(player);
        _awardHolds(player);
        _awardNudges(player);
    }

    function hold(uint _index) public {
        address player = _msgSender();
        _hold(player, _index);
    }

    function nudge(uint _index) public {
        address player = _msgSender();
        _nudge(player, _index);
    }

    function bankOf(address _player) public view returns(uint) {
        return _getBank(_player);
    }

    function creditBalanceOf(address _player) public view returns(uint) {
        return _getCredits(_player);
    }

    function holdsOf(address _player) public view returns(uint) {
        return _getHolds(_player);
    }

    function heldOf(address _player) public view returns(bool[3] memory) {
        return _getHeld(_player);
    }

    function nudgesOf(address _player) public view returns(uint) {
        return _getNudges(_player);
    }





    //behind the scenes
    function _addToPayTable(PayLineData calldata _payLine) private {
        _payTable.push(_payLine);
    }

    function _removeFromPayTable(PayLineData[] storage _table, uint _index) private {
        _table[_index] = _table[_table.length - 1];
        _table.pop();
    }

    function _getPayTable() private view returns(PayLineData[] storage) {
        return _payTable;
    }

    function _getPayTableLength() private view returns(uint) {
        return _getPayTable().length;
    }

    function _getPayLineData(uint _index) private view returns(PayLineData storage) {
        return _getPayTable()[_index];
    }

    function _getCreditPrice() private view returns(uint) {
        return _creditPrice;
    }

    function _setCreditPrice(uint _price) private {
        _creditPrice = _price;
    }
    
    function _getHistoricalResults(address _player) private view returns(string[3][] storage) {
        return _historicalResults[_player];
    } 

    function _getHistoricalResultsLength(address _player) private view returns(uint) {
        return _getHistoricalResults(_player).length;
    }

    function _getHistoricalResult(address _player, uint _index) private view returns(string[3] storage) {
        return _getHistoricalResults(_player)[_index];
    }

    function _getHistoricalWinnings(address _player) private view returns(uint[] storage) {
        return _historicalWinnings[_player];
    }

    function _getHistoricalWinningsLength(address _player) private view returns(uint) {
        return _getHistoricalWinnings(_player).length;
    }

    function _getHistoricalWinning(address _player, uint _index) private view returns(uint) {
        return _getHistoricalWinnings(_player)[_index];
    }



    function _getHeld(address _player) private view returns(bool[3] storage) {
        return _held[_player];
    }

    function _getPositions(address _player) private view returns(uint[3] storage) {
        return _positions[_player];
    }

    function _getReels() private view returns(string[][3] storage) {
        return _reels;
    }

    function _setReels(string[][3] memory _newReels) private {
        _reels = _newReels;
    }

    function _getBank(address _player) private view returns(uint) {
        return _bank[_player];
    }

    function _getCredits(address _player) private view returns(uint) {
        return _credits[_player];
    }

    function _getHolds(address _player) private view returns(uint) {
        return _holds[_player];
    }

    function _getNudges(address _player) private view returns(uint) {
        return _nudges[_player];
    }
    


    function _resetHeld(address _player) private {
        bool[3] storage held = _getHeld(_player);
        for(uint i; i < 3; i ++) {
            held[i] = false;
        }
    }

    function _clearHolds(address _player) private {
        _holds[_player] = 0;
    }

    function _clearNudges(address _player) private {
        _nudges[_player] = 0;
    }

    function _addToHolds(address _player, uint _value) private {
        _holds[_player] += _value;
    }

    function _addToNudges(address _player, uint _value) private {
        _nudges[_player] += _value;
    }

    function _decrementHolds(address _player) private {
        require(_holds[_player] > 0, "You have ran out of holds.");
        _holds[_player] --;
    }

    function _decrementNudges(address _player) private {
        require(_nudges[_player] > 0, "You have ran out of nudges.");
        _nudges[_player] --;
    }

    function _takeFromCredits(address _player, uint _value) private {
        require(_credits[_player] >= _value, "You have ran out of credits.");
        _credits[_player] -= _value;
        emit Spun(_player);
    }

    function _addToCredits(address _player, uint _value) private {
        _credits[_player] += _value;
        emit Deposit(_player, _value);
    }

    function _takeFromBank(address _player, uint _value) private {
        require(_bank[_player] >= _value, "Your bank balance is too low to withdraw this amount.");
        _bank[_player] -= _value;
        emit Withdraw(_player, _value);
    }

    function _addToBank(address _player, uint _value) private {
        _bank[_player] += _value;
        emit Won(_player, _value);
    }

    function _payForSpin(address _player) private {
        _takeFromCredits(_player, _creditPrice);
    }

    function _awardHolds(address _player) private {
        uint chance = _randomNumber(100);
        if(chance < _holdsChance) {
            uint holds = _randomNumber(_holdsMax - _holdsMin) + _holdsMin;
            _addToHolds(_player, holds);
        }
    }

    function _awardNudges(address _player) private {
        uint chance = _randomNumber(100);
        if(chance < _nudgesChance) {
            uint nudges = _randomNumber(_nudgesMax - _nudgesMin) + _nudgesMin;
            _addToNudges(_player, nudges);
        }
    }

    


    


    function _spin(address _player) private {
        string[][3] storage currentReels = _getReels();
        uint[3] storage positions = _getPositions(_player);
        bool[3] storage held = _getHeld(_player);
        for(uint i; i < 3; i ++) {
            if(!held[i]) {
                uint pos = _randomNumber(currentReels[i].length);
                positions[i] = pos;
            }
        }
    }



    function _nudge(address _player, uint _index) private {
        string[][3] storage currentReels = _getReels();
        uint[3] storage positions = _getPositions(_player);
        bool[3] storage held = _getHeld(_player);
        require(!held[_index], "Cannot nudge a held position.");
        uint pos = positions[_index];
        positions[_index] = (pos + 1) % currentReels[_index].length;
        _decrementNudges(_player);
        _payout(_player);
    }



    function _hold(address _player, uint _index) private {
        bool[3] storage held = _getHeld(_player);
        require(!held[_index], "Already held this position.");
        held[_index] = true;
        _decrementHolds(_player);
    }



    function _payout(address _player) private {
        string[][3] storage currentReels = _getReels();
        uint[3] storage positions = _getPositions(_player);
        string[3] memory result = [
            currentReels[0][positions[0]], 
            currentReels[1][positions[1]],
            currentReels[2][positions[2]]
        ];
        uint winnings;
        for(uint i; i < _getPayTableLength(); i ++) {
            PayLineData storage payLineData = _getPayLineData(i);
            string[3] memory payLine = payLineData.payLine;
            uint payout = payLineData.payout;
            if(keccak256(abi.encode(payLine)) == keccak256(abi.encode(result))) {
                _addToBank(_player, payout);
            }
            winnings += payout;
        }
        _logHistoricalResults(_player, result);
        _logHistoricalWinnings(_player, winnings);
    }

    function _getHoldsInfo() private view returns(uint chance, uint min, uint max) {
        return(_holdsChance, _holdsMin, _holdsMax);
    }

    function _getNudgesInfo() private view returns(uint chance, uint min, uint max) {
        return(_nudgesChance, _nudgesMin, _nudgesMax);
    }

    function _setHoldsInfo(uint _chance, uint _min, uint _max) private {
        (_holdsChance, _holdsMin, _holdsMax) = (_chance, _min, _max);
    }

    function _setNudgesInfo(uint _chance, uint _min, uint _max) private {
        (_nudgesChance, _nudgesMin, _nudgesMax) = (_chance, _min, _max);
    }

    function _logHistoricalResults(address _player, string[3] memory _result) private {
        string[3][] storage historicalResults = _getHistoricalResults(_player);
        historicalResults.push(_result);
    }
    function _logHistoricalWinnings(address _player, uint _winnings) private {
        uint[] storage historicalWinnings = _getHistoricalWinnings(_player);
        historicalWinnings.push(_winnings);
    }

    modifier noContract() {
        address sender = _msgSender();
        require(!sender.isContract(), "Contracts may not play slots.");
        _;
    }

    function _withdraw(address _to, uint _value) private {
        XYA.transfer(_to, _value);
    }

    function _getSalt() internal override pure returns(bytes memory) {
        return "slottywotty";
    }
}
