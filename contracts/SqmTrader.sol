/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

pragma solidity 0.4.24;

/// @title ERC777 SquareMetre Token (SQM) Trader
/// @author Jeremias Grenzebach, GoldenAcre B.V.
/// @dev This contract receives SQM from the minter and offers them against ETH for a set price by trader

import { GAccounts } from "./GAccounts.sol";
import { SafeMath } from "../../External-Contracts/openzeppelin-solidity/contracts/math/SafeMath.sol";



    /** -- External SQM-Token import -- 
    *
    * @notice importing the Golden Acre token SQM (SquareMetres)
    */
contract importToken {
    function send(address, uint256) public pure {  }
    function balanceOf(address) public pure returns (uint256) {  }
}



contract SqmTrader is GAccounts {
    using SafeMath for uint256;
    
    importToken public sqmToken;
    uint256 public EthPriceOfSqm;
    bool directTradeAllowed;
    
    
    
    /** -- Constructor -- 
    *
    * @notice Constructor to create Land Register
    */
    constructor()
    public
    {
        EthPriceOfSqm = 1 finney;
        directTradeAllowed = true;
    }
    
    
    function () 
    public 
    payable 
    {
        if (msg.sender != trader) {
            //require (directTradeAllowed);
            buySQMAgainstEther();                                    // Allow direct trades by sending eth to the contract
        }
    }
    
    
    /** -- Set Price in ETH for 1 SQM --
    *
    * @notice Price may only be set by trader account
    */
    
    function setEtherPrice(uint256 _EthPriceOfSqm) public onlyTrader {
        EthPriceOfSqm = _EthPriceOfSqm;
    }
    
    
    /** User buys SQM and pays in Ether
     * 
     * @notice 
     */
    function buySQMAgainstEther() public payable returns (uint256 amount) {
        require (EthPriceOfSqm != 0 && msg.value >= EthPriceOfSqm);             // Avoid dividing 0, sending small amounts and spam
        uint256 amountSqm = msg.value / EthPriceOfSqm;
        require (sqmToken.balanceOf(this) >= amountSqm);             
        sqmToken.send(msg.sender, amountSqm);
        //Transfer(this, msg.sender, amount);                                 // Execute an event reflecting the change
        return amountSqm;
    }


    /** Refund SQM or ETH to trader
     * 
     * @notice empty this contract by refunding to trader
     */
    function refundToTrader (uint256 _amountOfEth, uint256 _amountOfSqm) public onlyTrader {
        //uint256 eth = mul(_amountOfEth, 1 ether);
        msg.sender.transfer(_amountOfEth);
        require (sqmToken.balanceOf(this) >= _amountOfSqm);                                   // Check if it has enough to sell
        sqmToken.send(msg.sender, _amountOfSqm);
        //Transfer(this, msg.sender, dcn);                                    // Execute an event reflecting the change
    }

    
    
    
    /**
     * Update SQM-token addrress
     * 
     * @param _newTokenAddress Address of the new SQM-token
     */
    
    function updateToken(address _newTokenAddress) public onlyOwner {
        sqmToken = importToken(_newTokenAddress);
    }
    
    
    function haltDirectTrade() public onlyTrader {
        directTradeAllowed = false;
    }
    function unhaltDirectTrade() public onlyTrader {
        directTradeAllowed = true;
    }
    
}

