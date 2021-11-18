// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "luk1529_solidity/contracts/utils/Random.sol";

contract Roulette is Ownable, Random {
    //profit takers
    struct ProfitTaker {
        address addr;
        uint points;
    }
    
    
    
    
    IERC20 XYA;
    constructor(IERC20 _XYA, uint _numberOfSpaces) {
        XYA = _XYA;
        _initialiseWheel(_numberOfSpaces);
        
        
        //map strings to enum values
        colours["red"] = Colours.red;
        colours["black"] = Colours.black;
        colours["green"] = Colours.green;
        betTypes["number"] = BetTypes.number;
        betTypes["red"] = BetTypes.red;
        betTypes["black"] = BetTypes.black;
        betTypes["odd"] = BetTypes.odd;
        betTypes["even"] = BetTypes.even;
    }
    
    
    
    //events
    event Spun(Space space);
    event BetOn(address indexed player, string betType, uint number, uint bet);
    event Won(address indexed player, uint amount);
    
    
    
    //colours
    enum Colours {red, black, green}
    mapping(string => Colours) colours;
    
    
    
    //wheel
    struct Space {
        uint number;
        string colour;
    }
    
    
    
    //bet types
    enum BetTypes {number, red, black, green, odd, even}
    mapping(string => BetTypes) betTypes;
    
    
    
    //bet data type
    struct Bet {
        address player;
        string betType;
        uint number;
        uint bet;
    }
    
    
    
    //parameters
    uint minBetValue;
    uint maxBetValue;
    uint maxBets;
    uint timeLimit;
    
    
    
    //data
    Space[] wheel;
    Space lastSpace;
    Bet[] bets;
    Bet[] lastRoundWinningBets;
    uint nextSpinAt;
    ProfitTaker[] profitTakers;
    uint profitTakerPoints;
    
    
    
    //public functions
    function getWheel() public view returns(Space[] memory) {
        return wheel;
    }
    function getLastSpace() public view returns(Space memory) {
        return lastSpace;
    }
    function getTimeLeft() public view returns(uint) {
        return _timeLeft();
    }
    function getCurrentBets() public view returns(Bet[] memory) {
        return bets;
    }
    function getLastRoundWinningBets() public view returns(Bet[] memory) {
        return lastRoundWinningBets;
    }
    function makeBet(string calldata _betType, uint _number, uint _bet) public {
        _receiveBet(msg.sender, _betType, _number, _bet);
    }
    function spin() public {
        _spin();
    }
    
    
    
    //receive a bet
    function _receiveBet(address _player, string memory _betType, uint _number, uint _bet) private {
        if (betTypes[_betType] == BetTypes.number) {
            _betType = "number";
        }
        Bet memory bet = Bet(_player, _betType, _number, _bet);
        require(bets.length < maxBets, "There are too many bets this round. Please wait until the next round.");
        require(bet.bet >= minBetValue, "Bet too low for table.");
        require(bet.bet <= maxBetValue, "Bet too high for table.");
        _receive(bet.player, bet.bet);
        bets.push(bet);
        emit BetOn(_player, _betType, _number, _bet);
    }
    
    
    
    //spin
    function _getRandomSpace() private returns(Space storage space) {
        uint index = _randomNumber(wheel.length);
        return wheel[index];
    }
    function _spin() private {
        require(_timeLeft() == 0, "Please wait until spinning to allow more bets to come in.");
        delete lastRoundWinningBets;
        Space storage result = _getRandomSpace();
        lastSpace = result;
        for(uint i; i < bets.length; i ++) {
            uint prize = _getPrize(result, bets[i]);
            if(prize > 0) {
                _pay(bets[i].player, prize);
                lastRoundWinningBets.push(bets[i]);
                emit Won(bets[i].player, prize);
            }
        }
        delete bets;
        nextSpinAt = block.timestamp + timeLimit;
        emit Spun(result);
    }
    
    
    
    //get prize for a bet
    function _getPrize(Space storage _space, Bet storage _bet) private view returns(uint prize) {
        BetTypes betType = betTypes[_bet.betType];
        if (betType == BetTypes.number) {
            if(_bet.number == _space.number) {
                prize = _bet.bet * wheel.length - 1;
            }
        } else if(betType == BetTypes.red) {
            if(colours[_space.colour] == Colours.red) {
                prize = _bet.bet * 2;
            }
        } else if(betType == BetTypes.black) {
            if(colours[_space.colour] == Colours.black) {
                prize = _bet.bet * 2;
            }
        } else if(betType == BetTypes.green) {
            if(colours[_space.colour] == Colours.green) {
                prize = _bet.bet * wheel.length - 1;
            }
        } else if(betType == BetTypes.odd) {
            if(_isOdd(_space.number)) {
                prize = _bet.bet * 2;
            }
        } else if(betType == BetTypes.even) {
            if(_isEven(_space.number)) {
                prize = _bet.bet * 2;
            }
        }
    }
    
    

    //create the wheel
    function _initialiseWheel(uint _numberOfSpaces) private {
        require(_isOdd(_numberOfSpaces), "Wheel must have an odd number of spaces.");
        uint i;
        wheel.push(Space(i,"green"));
        i ++;
        while(i < (_numberOfSpaces / 2) + 1) {
            wheel.push(Space(i, "red"));
            i ++;
        }
        while(i < _numberOfSpaces) {
            wheel.push(Space(i, "black"));
            i ++;
        }
    }
    
    
    
    
    //XYA
    function _pay(address _player, uint _amount) private {
        XYA.transfer(_player, _amount);
    }
    function _receive(address _player, uint _amount) private {
        XYA.transferFrom(_player, address(this), _amount);
        _splitToProfitTakers(_amount / wheel.length);
    }
    function _splitToProfitTakers(uint _amount) private {
        if(profitTakerPoints == 0) {
            return;
        }
        uint XYAPerPoint = _amount / profitTakerPoints;
        for(uint i; i < profitTakers.length; i ++) {
            _pay(profitTakers[i].addr, profitTakers[i].points * XYAPerPoint);
        }
    }
    
    
    //time
    function _timeLeft() private view returns(uint) {
        return block.timestamp < nextSpinAt ? nextSpinAt - block.timestamp : 0;
    }
    
    
    
    //misc
    function _isOdd(uint _number) private pure returns(bool) {
        return _number % 2 == 1;
    }
    function _isEven(uint _number) private pure returns(bool) {
        return _number % 2 == 0;
    }
    
    
    
    //admin
    function setParams(uint _minBetValue, uint _maxBetValue, uint _maxBets, uint _timeLimit) public onlyOwner {
        (minBetValue, maxBetValue, maxBets, timeLimit) = (_minBetValue, _maxBetValue, _maxBets, _timeLimit);
    }
    function withdraw(uint _amount) public onlyOwner {
        _pay(msg.sender, _amount); 
    }
    function getProfitTakers() public view onlyOwner returns(ProfitTaker[] memory) {
        return profitTakers;
    }
    function addProfitTaker(ProfitTaker calldata _profitTaker) public onlyOwner {
        profitTakers.push(_profitTaker);
        profitTakerPoints += _profitTaker.points;
    }
    function deleteProfitTakers() public onlyOwner {
        delete profitTakers;
        profitTakerPoints -= profitTakerPoints;
    }

    function _getSalt() internal override view returns(bytes memory) {
        return "rourou";
    }
}