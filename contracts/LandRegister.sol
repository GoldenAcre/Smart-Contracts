/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

pragma solidity 0.4.24;

/// @title GoldenAcre land register Contract
/// @author Jeremias Grenzebach, GoldenAcre B.V.
/// @dev This contract uses the SQM-token contract (ERC777/ERC20)

import { GAccounts } from "./GAccounts.sol";


// SQM-token import
contract importToken {
  function mint(uint256, bytes) pure internal {  }
  function burn(uint256, bytes, bytes) pure internal {  }
}







contract LandRegister is GAccounts {
    
    uint public numEntries;
    uint256 public entryID;    //unique identifier in land register
    importToken public sqmToken;
    
    
    //mapping(uint256 => EntryInLandRegister) records;
    EntryInLandRegister[] public records;
    
    struct EntryInLandRegister {
        
        
        bytes32 entryHash; //Hash über alle untigen Daten

        string cadastreID; //Katasternummer des Grundstücks
        uint256[2] coordinates; // Längen- und Breitengrade: 43.223383, 27.998749   -  (zusätzlich verschiedene Systeme, damit zukunftssicher: OpenStreetMap, what3words)
        
        uint256 sqmOfEntry; //Quadratmeter des Grundstücks
        
        bool ownedByGoldenAcre;// Eigentum von GoldenAcre ja/nein
        string previousOwner; //Verkäufer
        uint256 dateOfPurchase; //Datum des Kaufs/Verkaufs
        uint256 dateAddedToRegister; //Datum der Grundbucheintragung
        string addressOfRegistrationOffice; //Ort des Eintragungsamtes
        string geohash; // Ein (ipfs-)Link zum PDF des Grundbuchauszuges
        
        bool organicFarming; //Ökologisch bewirtschaftet ja/nein
        
        uint256 circulatingSQM;
        
    }
    
    
    
    
    /* -- Constructor -- */
    //
    /// @notice Constructor to create SQM
    constructor()
    public
    {
        
    }
    
    

    
    
    
    /**
     * Add Record
     *
     * @param _cadastreID unique identifier from original land register
     * @param _coordinates geographical center of the land in format: 43.283383, 26.998749
     * @param _sqmOfEntry area of the property in square metres
     * @param _ownedByGoldenAcre -
     * @param _previousOwner previous owner of the property who sold to goldenAcre B.V.
     * @param _dateOfPurchase date when GoldenAcre B.V. purchased this land
     * @param _addressOfRegistrationOffice address where land registry containing this property is based.
     * @param _geohash -
     * @param _circulatingSQM Amount of SQM-tokens generated by this land (equals sqmOfEntry)
     * 
     */
     
    function newEntry(
        string _cadastreID,
        uint256[2] _coordinates,
        uint256 _sqmOfEntry,
        bool _ownedByGoldenAcre,
        string _previousOwner,
        uint256 _dateOfPurchase,
        string _addressOfRegistrationOffice,
        string _geohash,
        uint256 _circulatingSQM
    )
        public onlyOwner returns (uint proposalID)
    {
        entryID = records.length++;
        EntryInLandRegister storage e = records[entryID];
        
        e.entryHash = keccak256(_cadastreID, _coordinates, _coordinates, _sqmOfEntry, _ownedByGoldenAcre, _previousOwner, _dateOfPurchase, _addressOfRegistrationOffice, _geohash, _circulatingSQM);
        e.cadastreID = _cadastreID;
        e.coordinates = _coordinates;
        e.sqmOfEntry = _sqmOfEntry;
        e.ownedByGoldenAcre = _ownedByGoldenAcre;
        e.previousOwner = _previousOwner;
        e.dateOfPurchase = _dateOfPurchase;
        e.dateAddedToRegister = now;
        e.addressOfRegistrationOffice = _addressOfRegistrationOffice;
        e.geohash = _geohash;
        e.circulatingSQM = _circulatingSQM;
        
        //ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numEntries = entryID+1;

        return entryID;
    }
    
    
    
    
    
    
    
    
    
    
    
    function () 
    public 
    payable 
    {
        // fallback function
    }
    
    
    /**
     * Update SQM-token addrress
     * 
     * @param _newTokenAddress Address of the new SQM-token
     */
    
    function updateToken(address _newTokenAddress) public onlyOwner {
        sqmToken = importToken(_newTokenAddress);
    }
    
    
}



