//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Casino is Context {
    IERC20 XYA;

    address[10] leaderboard;
    
    uint totalInflow;
    uint totalOutflow;

    constructor(IERC20 _XYA) {
        XYA = _XYA;
    }

    struct PlayerData {
        uint credit;
        uint bank; 
        uint totalSpent;
        uint totalWon;
    }

    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);

    mapping(address => bool) _approvedGames;
    mapping(address => PlayerData) _playerData;

    function deposit(uint _amount) public {
        _deposit(_msgSender(), _amount);
    }
    function withdraw(uint _amount) public {
        _withdraw(_msgSender(), _amount);
    }

    function _deposit(address _from, uint _amount) private {
        XYA.transferFrom(_from, address(this), _amount);
        _playerData[_from].credit += _amount;
        emit Deposit(_from, _amount);
    }
    function _withdraw(address _to, uint _amount) private {
        _playerData[_to].bank -= _amount;
        XYA.transferFrom(address(this), _to, _amount);
    }

    function _registerBet(address _for, uint _amount) private {
        _playerData[_for].credit -= _amount;
        totalInflow += _amount;
    }
    function _registerWin(address _for, uint _amount) private {
        _playerData[_for].bank += _amount;
        totalOutflow += _amount;
    }
    
    function _setApproval(address _for, bool _approval) private {
        _approvedGames[_for] = _approval;
    }
    modifier _isApproved(address _game) {
        require(_approvedGames[_game], "Please register this game as part of the casino.");
        _;
    }

    
}