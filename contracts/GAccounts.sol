/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

pragma solidity 0.4.24;


/**
 * @title Contract for GoldenAcre SQM main accounts
 * @author Jeremias Grenzebach, GoldenAcre B.V.
 * @dev This token contract is to be imported in SQM.sol, an ERC777, pre-standard and ERC20 compatible token contract. 
 * It provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */


contract GAccounts {
    
    address public owner;
    address public minter;
    address public trader;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  event MintershipRenounced(address indexed previousMinter);
  event MintershipTransferred(
    address indexed previousMinter,
    address indexed newMinter
  );
  event TradershipRenounced(address indexed previousTrader);
  event TradershipTransferred(
    address indexed previousTrader,
    address indexed newTrader
  );


  /**
   * @dev The constructor sets the original `authorities` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    minter = msg.sender;
    trader = msg.sender;
    
  }


//---------------------- Owner ----------------------

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
    
//---------------------- /Owner ----------------------   
    



//---------------------- Minter ---------------------- 

  /**
   * @dev Throws if called by any account other than the minter.
   */
  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

  /**
   * @dev Allows the current OWNER!!! to transfer control of the contract to a newMinter. newMinter is likely to be the land register contract.
   * @param newMinter The address to transfer mintership to.
   */
  function transferMintership(address newMinter) public onlyOwner {
    require(newMinter != address(0));
    emit MintershipTransferred(minter, newMinter);
    minter = newMinter;
  }

//---------------------- /Minter ---------------------- 
  
  
  

//---------------------- Trader ---------------------- 

 /**
   * @dev Throws if called by any account other than the trader.
   */
  modifier onlyTrader() {
    require(msg.sender == trader);
    _;
  }

  /**
   * @dev Allows the current OWNER!!! to transfer control of the contract to a newTrader.
   * @param newTrader The address to transfer mintership to.
   */
  function transferTradership(address newTrader) public onlyOwner {
    require(newTrader != address(0));
    emit TradershipTransferred(trader, newTrader);
    trader = newTrader;
  }

//---------------------- /Trader ---------------------- 
  
  
}