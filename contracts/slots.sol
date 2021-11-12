pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Random {
    uint nonce;
    function _randomNumber(uint _upTo) internal returns(uint number) {
        if(_upTo == 0) {
            _upTo ++;
        }
        uint res = uint(keccak256(abi.encodePacked(block.timestamp, "tailchinkra", nonce)));
        number = res % _upTo;
        nonce ++;
    }
}
contract Slots is Ownable, Random {
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
    function addToPayTable(PayLineData calldata _payLine) public onlyOwner {
        _addToPayTable(_payLine);
    }

    function removeFromPayTable(uint _index) public onlyOwner {
        _removeFromPayTable(_index);
    }

    function getPayTableLength() public view returns(uint) {
        return _getPayTableLength();
    }

    function getPayLineData(uint _index) public view returns(PayLineData memory) {
        return _getPayLineData(_index);
    }



    //previous results
    function getHistoricalResultsLength(address _for) public view returns(uint) {
        return _getHistoricalResultsLength(_for);
    }

    function getHistoricalResultOfPlayerByIndex(address _for, uint _index) public view returns(string[3] memory) {
        return _getHistoricalResult(_for, _index);
    }

    function getHistoricalWinningsLength(address _for) public view returns(uint) {
        return _getHistoricalResultsLength(_for);
    }

    function getHistoricalWinningOfPlayerbyIndex(address _for, uint _index) public view returns(uint) {
        return _getHistoricalWinning(_for, _index);
    }



    //reel data
    function getReels() public view returns(string[][3] memory ) {
        return _getReels();
    }

    function positionsOf(address _player) public view returns(uint[3] memory) {
        return _getPositions(_player);
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

    function spin() public {
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



    





    function _addToPayTable(PayLineData calldata _payLine) private {
        _payTable.push(_payLine);
    }

    function _removeFromPayTable(uint _index) private {
        PayLineData[] storage table = _getPayTable();
        table[_index] = table[table.length - 1];
        table.pop();
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


    
    function _getHistoricalResults(address _for) private view returns(string[3][] storage) {
        return _historicalResults[_for];
    } 

    function _getHistoricalResultsLength(address _for) private view returns(uint) {
        return _getHistoricalResults(_for).length;
    }

    function _getHistoricalResult(address _for, uint _index) private view returns(string[3] storage) {
        return _getHistoricalResults(_for)[_index];
    }

    function _getHistoricalWinnings(address _for) private view returns(uint[] storage) {
        return _historicalWinnings[_for];
    }

    function _getHistoricalWinningsLength(address _for) private view returns(uint) {
        return _getHistoricalWinnings(_for).length;
    }

    function _getHistoricalWinning(address _for, uint _index) private view returns(uint) {
        return _getHistoricalWinnings(_for)[_index];
    }



    function _getHeld(address _for) private view returns(bool[3] storage) {
        return _held[_for];
    }

    function _getPositions(address _for) private view returns(uint[3] storage) {
        return _positions[_for];
    }

    function _getReels() private view returns(string[][3] storage) {
        return _reels;
    }

    function _getBank(address _for) private view returns(uint) {
        return _bank[_for];
    }

    function _getCredits(address _for) private view returns(uint) {
        return _credits[_for];
    }
    


    function _resetHeld(address _for) private {
        bool[3] storage held = _getHeld(_for);
        for(uint i; i < 3; i ++) {
            held[i] = false;
        }
    }

    function _clearHolds(address _for) private {
        _holds[_for] = 0;
    }

    function _clearNudges(address _for) private {
        _nudges[_for] = 0;
    }

    function _addToHolds(address _for, uint _value) private {
        _holds[_for] += _value;
    }

    function _addToNudges(address _for, uint _value) private {
        _nudges[_for] += _value;
    }

    function _decrementHolds(address _for) private {
        require(_holds[_for] > 0, "You have ran out of holds.");
        _holds[_for] --;
    }

    function _decrementNudges(address _for) private {
        require(_nudges[_for] > 0, "You have ran out of nudges.");
        _nudges[_for] --;
    }

    function _takeFromCredits(address _for, uint _value) private {
        require(_credits[_for] >= _value, "You have ran out of credits.");
        _credits[_for] -= _value;
    }

    function _addToCredits(address _for, uint _value) private {
        _credits[_for] += _value;
        emit Deposit(_for, _value);
    }

    function _takeFromBank(address _for, uint _value) private {
        require(_bank[_for] >= _value, "Your bank balance is too low to withdraw this amount.");
        _bank[_for] -= _value;
        emit Withdraw(_for, _value);
    }

    function _addToBank(address _for, uint _value) private {
        _bank[_for] += _value;
    }

    function _payForSpin(address _for) private {
        _takeFromCredits(_for, _creditPrice);
    }

    function _awardHolds(address _for) private {
        uint chance = _randomNumber(100);
        if(chance < _holdsChance) {
            uint holds = _randomNumber(_holdsMax - _holdsMin) + _holdsMin;
            _addToHolds(_for, holds);
        }
    }

    function _awardNudges(address _for) private {
        uint chance = _randomNumber(100);
        if(chance < _nudgesChance) {
            uint nudges = _randomNumber(_nudgesMax - _nudgesMin) + _nudgesMin;
            _addToNudges(_for, nudges);
        }
    }

    


    


    function _spin(address _for) private {
        string[][3] storage reels = _getReels();
        uint[3] storage positions = _getPositions(_for);
        bool[3] storage held = _getHeld(_for);
        for(uint i; i < 3; i ++) {
            if(!held[i]) {
                uint pos = positions[i];
                positions[i] = (pos + 1) % reels[i].length;
            }
        }
        emit Spun(_for);
    }



    function _nudge(address _for, uint _index) private {
        string[][3] storage reels = _getReels();
        uint[3] storage positions = _getPositions(_for);
        bool[3] storage held = _getHeld(_for);
        require(!held[_index], "Cannot nudge a held position.");
        uint pos = positions[_index];
        positions[_index] = (pos + 1) % reels[_index].length;
        _decrementNudges(_for);
        _payout(_for);
    }



    function _hold(address _for, uint _index) private {
        bool[3] storage held = _getHeld(_for);
        require(!held[_index], "Already held this position.");
        held[_index] = true;
        _decrementHolds(_for);
    }



    function _payout(address _for) private {
        string[][3] storage reels = _getReels();
        uint[3] storage positions = _getPositions(_for);
        string[3] memory result = [
            reels[0][positions[0]], 
            reels[1][positions[1]],
            reels[2][positions[2]]
        ];
        uint winnings;
        for(uint i; i < _getPayTableLength(); i ++) {
            PayLineData storage payLineData = _getPayLineData(i);
            string[3] memory payLine = payLineData.payLine;
            uint payout = payLineData.payout;
            if(keccak256(abi.encode(payLine)) == keccak256(abi.encode(result))) {
                XYA.transfer(_for, payout);
                emit Won(_for, payout);
            }
            winnings += payout;
        }
        _logHistoricalResults(_for, result);
        _logHistoricalWinnings(_for, winnings);
    }



    function _logHistoricalResults(address _for, string[3] memory _result) private {
        string[3][] storage historicalResults = _getHistoricalResults(_for);
        historicalResults.push(_result);
    }
    function _logHistoricalWinnings(address _for, uint _winnings) private {
        uint[] storage historicalWinnings = _getHistoricalWinnings(_for);
        historicalWinnings.push(_winnings);
    }
}