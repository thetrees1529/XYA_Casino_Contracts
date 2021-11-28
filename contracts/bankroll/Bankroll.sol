//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "luk1529_solidity/contracts/fee/FeeTakersERC20.sol";

contract Bankroll is Context, Ownable, FeeTakers {
    IERC20 _XYA;
    
    
    uint _totalInflow;
    uint _totalOutflow;


    constructor(IERC20 XYA_) FeeTakers(XYA_) {
        _setXYA(XYA_);
    }

    struct PlayerData {
        uint credit;
        uint bank; 
        uint totalSpent;
        uint totalWon;
    }


    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event Won(address indexed to, uint amount);
    event Spent(address indexed from, uint amount);

    event ProfitTaken(uint amount);

    mapping(address => bool) _approved;
    mapping(address => PlayerData) _playerData;


    //user can deposit to their credit balance and withdraw funds from their bank balance
    function deposit(uint amount) public {
        _depositFrom(_msgSender(), amount);
    }
    function withdraw(uint amount) public {
        _withdrawTo(_msgSender(), amount);
    }


    //approved contracts (games) can take funds from players' credit balances and award funds to their bank balances
    function playFrom(address player, uint amount) public onlyApproved {
        _playFrom(player, amount);
    }
    function winTo(address player, uint amount) public onlyApproved {
        _winTo(player, amount);
    }


    //audit which contracts can spend on behalf of players in Freyala's casino
    function setApproval(address addr, bool approval) public onlyOwner {
        _setApproval(addr, approval);
    }

    modifier onlyApproved() {
        require(_approved[_msgSender()]);
        _;
    }


    function _getPlayerData(address player) private view returns(PlayerData storage) {
        return _playerData[player];
    }

    function _depositFrom(address player, uint amount) private {
        PlayerData storage playerData = _getPlayerData(player);
        playerData.credit += amount;
        _XYA.transferFrom(player, address(this), amount);
        emit Deposit(player, amount);
    }

    function _withdrawTo(address player, uint amount) private {
        PlayerData storage playerData = _getPlayerData(player);
        playerData.bank -= amount;
        _XYA.transferFrom(address(this), player, amount);
        emit Withdraw(player, amount);
    }

    function _playFrom(address player, uint amount) private {
        PlayerData storage playerData = _getPlayerData(player);
        _totalInflow += amount;
        playerData.credit -= amount;
        emit Spent(player, amount);
    }

    function _winTo(address player, uint amount) private {
        PlayerData storage playerData = _getPlayerData(player);
        _totalOutflow += amount;
        playerData.bank += amount;
        emit Won(player, amount);
        _takeProfit();
    }

    function _getNetBalance() private view returns(int netProfit) {
        netProfit = int(_totalInflow) - int(_totalOutflow);
    }

    function _takeProfit() private {
        int profit = _getNetBalance();
        if(profit > 0) {
            uint toDistribute = uint(profit);
            _totalOutflow += toDistribute;
            _distributeFee(toDistribute);
            emit ProfitTaken(toDistribute);
        }
    }

    function _setApproval(address addr, bool approval) private {
        _approved[addr] = approval;
    }

    function _setXYA(IERC20 XYA_) private {
        _XYA = XYA_;
    }

    
}