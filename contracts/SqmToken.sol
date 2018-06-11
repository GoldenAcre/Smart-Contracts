/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

pragma solidity 0.4.24;

/// @title ERC777 SquareMetre Token (SQM) Contract
/// @author Jeremias Grenzebach, GoldenAcre B.V.
/// @dev This token contract is based on ERC777, pre-standard and ERC20 compatible.

import { ERC820Implementer } from "../../External-Contracts/eip820/contracts/ERC820Implementer.sol";  //Rechange from Testnet-address
import { GAccounts } from "./GAccounts.sol";
import { SafeMath } from "../../External-Contracts/openzeppelin-solidity/contracts/math/SafeMath.sol";
import { ERC20Token } from "../../External-Contracts/ERC777/contracts/ERC20Token.sol";
import { ERC777Token } from "../../External-Contracts/ERC777/contracts/ERC777Token.sol";
import { ERC777TokensSender } from "../../External-Contracts/ERC777/contracts/ERC777TokensSender.sol";
import { ERC777TokensRecipient } from "../../External-Contracts/ERC777/contracts/ERC777TokensRecipient.sol";


contract SqmToken is GAccounts, ERC20Token, ERC777Token, ERC820Implementer {
    using SafeMath for uint256;

    string private mName;
    string private mSymbol;
    uint256 private mGranularity;
    uint256 private mTotalSupply;
    uint256 private mMaxSupply;
    

    bool private mErc20compatible;

    mapping(address => uint) private mBalances;
    mapping(address => mapping(address => bool)) private mAuthorized;
    mapping(address => mapping(address => uint256)) private mAllowed;

    /* -- Constructor -- */
    //
    /// @notice Constructor to create SQM
    constructor()
        public
    {
        mName = "SquareMeter";
        mSymbol = "SQM";
        mTotalSupply = 0;
        mMaxSupply = 50000000000;  // 50 billion
        mErc20compatible = true;
        mGranularity = 1;

        setInterfaceImplementation("ERC20Token", this);
        setInterfaceImplementation("ERC777Token", this);
    }

    /* -- ERC777 Interface Implementation -- */
    //
    /// @return the name of the token
    function name() public constant returns (string) { return mName; }

    /// @return the symbol of the token
    function symbol() public constant returns (string) { return mSymbol; }

    /// @return the granularity of the token
    function granularity() public constant returns (uint256) { return mGranularity; }

    /// @return the total supply of the token
    function totalSupply() public constant returns (uint256) { return mTotalSupply; }
    
    /// @return the max supply of the token
    function maxSupply() public constant returns (uint256) { return mMaxSupply; }

    /// @notice Return the account balance of some account
    /// @param _tokenHolder Address for which the balance is returned
    /// @return the balance of `_tokenAddress`.
    function balanceOf(address _tokenHolder) public constant returns (uint256) { return mBalances[_tokenHolder]; }

    /// @notice Send `_amount` of tokens to address `_to`
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    function send(address _to, uint256 _amount) public {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", true);
    }

    /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, _to, _amount, _userData, msg.sender, "", true);
    }

    /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Authorized
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Revoke a third party `_operator`'s rights to manage (send) `msg.sender`'s tokens.
    /// @param _operator The operator that wants to be Revoked
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
    /// @param _operator address to check if it has the right to manage the tokens
    /// @param _tokenHolder address which holds the tokens to be managed
    /// @return `true` if `_operator` is authorized for `_tokenHolder`
    function isOperatorFor(address _operator, address _tokenHolder) public constant returns (bool) {
        return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(_from, _to, _amount, _userData, msg.sender, _operatorData, true);
    }

    /* -- Mint And Burn Functions (not part of the ERC777 standard, only the Events/tokensReceived are) -- */
    //
    /// @notice Generates `_amount` tokens to be assigned to `Minter`
    ///  Sample mint function to showcase the use of the `Minted` event and the logic to notify the recipient.
    /// @param _amount The quantity of tokens generated
    /// @param _operatorData Data that will be passed to the recipient as a first transfer
    function mint(uint256 _amount, bytes _operatorData) public onlyMinter {
        requireMultiple(_amount);
        require(mTotalSupply < mMaxSupply);
        mTotalSupply = mTotalSupply.add(_amount);
        mBalances[trader] = mBalances[trader].add(_amount);

        callRecipient(msg.sender, 0x0, trader, _amount, "", _operatorData, true);

        emit Minted(msg.sender, trader, _amount, _operatorData);
        if (mErc20compatible) { emit Transfer(0x0, trader, _amount); }
    }


    /// @notice Burns `_amount` tokens from `minter`
    ///  Sample burn function to showcase the use of the `Burned` event.
    /// @param _amount The quantity of tokens to burn
    function burn(uint256 _amount, bytes _userData, bytes _operatorData) public onlyMinter {
        requireMultiple(_amount);

        callSender(msg.sender, minter, 0x0, _amount, _userData, _operatorData);

        require(balanceOf(minter) >= _amount);

        mBalances[minter] = mBalances[minter].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        emit Burned(msg.sender, minter, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(minter, 0x0, _amount); }
    }

    /* -- ERC20 Compatible Methods -- */
    //
    /// @notice This modifier is applied to erc20 obsolete methods that are
    ///  implemented only to maintain backwards compatibility. When the erc20
    ///  compatibility is disabled, this methods will fail.
    modifier erc20 () {
        require(mErc20compatible);
        _;
    }

    /// @notice Disables the ERC20 interface. This function can only be called
    ///  by the owner.
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
    }

    /// @notice Re enables the ERC20 interface. This function can only be called
    ///  by the owner.
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /// @notice For Backwards compatibility
    /// @return The decimls of the token. Forced to 18 in ERC777.
    function decimals() public erc20 constant returns (uint8) { return uint8(18); }

    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

        // Cannot be after doSend because of tokensReceived re-entry
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(_from, _to, _amount, "", msg.sender, "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can't be done, it should fail.
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public erc20 constant returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }

    /* -- Helper Functions -- */
    //
    /// @notice Internal function that ensures `_amount` is multiple of the granularity
    /// @param _amount The quantity that want's to be checked
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

    /// @notice Check whether an address is a regular address or not.
    /// @param _addr Address of the contract that has to be checked
    /// @return `true` if `_addr` is a regular address (not a contract)
    function isRegularAddress(address _addr) internal constant returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line no-inline-assembly
        return size == 0;
    }

    /// @notice Helper function actually performing the sending of tokens.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `erc777_tokenHolder`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
        private
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));          // forbid sending to 0x0 (=burning)
        require(mBalances[_from] >= _amount); // ensure enough funds

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) private {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

    /// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    ///  implementing `ERC777TokensSender`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    ) private {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation != 0) {
            ERC777TokensSender(senderImplementation).tokensToSend(
                _operator, _from, _to, _amount, _userData, _operatorData);
        }
    }
}
