/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

pragma solidity 0.4.24;

/// @title GoldenAcre land register Contract
/// @author Jeremias Grenzebach, GoldenAcre B.V.
/// @dev This contract uses the SQM-token contract (ERC777/ERC20)

import { GAccounts } from "./GAccounts.sol";


/* -- External SQM-Token import -- */
    //
    /// @notice importing the Golden Acre token SQM (SquareMetres)
contract importToken {
    function mint(uint256, bytes) public pure {  }
    function burn(uint256, bytes, bytes) public pure {  }
}







contract LandRegister is GAccounts {
    
    importToken public sqmToken;
    uint public numEntries;
    uint256 public landEntryID;    //unique identifier in land register
    
    
    //mapping(uint256 => EntryInLandRegister) landRecords;
    EntryInLandRegister[] public landRecords;
    
    struct EntryInLandRegister {
        bytes32 entryHash; //Hash über alle untigen Daten
        string cadastreID; //Katasternummer des Grundstücks
        uint256 coordinates; // Längen- und Breitengrade: 43.223383, 27.998749   -  (zusätzlich verschiedene Systeme, damit zukunftssicher: OpenStreetMap, what3words)
        uint256 sqmOrSQM; //Quadratmeter des Grundstücks
        bool ownedByGoldenAcre;// Eigentum von GoldenAcre ja/nein
        string previousOwner; // Verkäufer an GoldenAcre
        uint256 dateOfPurchase; //Datum des Kaufs/Verkaufs
        uint256 dateAddedToRegister; //Datum der Grundbucheintragung
        string addressOfRegistrationOffice; //Ort des Eintragungsamtes
        string geohash; // Ein (ipfs-)Link zum PDF des Grundbuchauszuges
    }
    
    
    
    
    /* -- Constructor -- */
    //
    /// @notice Constructor to create Land Register
    constructor()
    public
    {

    }
    
        function () 
    public 
    payable 
    {
        // fallback function
    }
    

    
    
    
    /**
     * Add Record
     *
     * @param _cadastreID unique identifier from original land register
     * @param _coordinates geographical center of the land in format: 43.283383, 26.998749
     * @param _sqmOrSQM area of the property in square metres
     * @param _ownedByGoldenAcre -
     * @param _previousOwner previous owner of the property who sold to goldenAcre B.V.
     * @param _dateOfPurchase date when GoldenAcre B.V. purchased this land
     * @param _addressOfRegistrationOffice address where land registry containing this property is based.
     * @param _geohash jhj
     * 
     */
     
    function newLandEntry(
        string _cadastreID,
        uint256 _coordinates,
        uint256 _sqmOrSQM,
        bool _ownedByGoldenAcre,
        string _previousOwner,
        uint256 _dateOfPurchase,
        string _addressOfRegistrationOffice,
        string _geohash
    )
        public onlyMinter returns (uint256 landID)
    {
        landEntryID = landRecords.length++;
        EntryInLandRegister storage e = landRecords[landEntryID];
        
        e.entryHash = keccak256(abi.encodePacked(_cadastreID, _coordinates, _sqmOrSQM, _ownedByGoldenAcre, _previousOwner, _dateOfPurchase, _addressOfRegistrationOffice, _geohash));
        e.cadastreID = _cadastreID;
        e.coordinates = _coordinates;
        e.sqmOrSQM = _sqmOrSQM;
        e.ownedByGoldenAcre = _ownedByGoldenAcre;
        e.previousOwner = _previousOwner;
        e.dateOfPurchase = _dateOfPurchase;
        e.dateAddedToRegister = now;
        e.addressOfRegistrationOffice = _addressOfRegistrationOffice;
        e.geohash = _geohash;
        
        //ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numEntries = landEntryID+1;
        
        //sqmToken.mint(_sqmOrSQM, "123");

        return landEntryID;
    }
    
    
    function getLandEntry ( uint256 _landEntryID ) 
        public view returns ( 
            bytes32 entryHash, 
            string cadastreID, 
            uint256 coordinates, 
            uint256 sqmOrSQM, 
            bool ownedByGoldenAcre, 
            string previousOwner,
            uint256 dateOfPurchase,
            uint256 dateAddedToRegister,
            string addressOfRegistrationOffice,
            string geohash

        )
    {
       EntryInLandRegister storage e = landRecords[_landEntryID];
       
            entryHash = e.entryHash;
            cadastreID = e.cadastreID;
            coordinates = e.coordinates; 
            sqmOrSQM = e.sqmOrSQM;
            ownedByGoldenAcre = e.ownedByGoldenAcre; 
            previousOwner = e.previousOwner;
            dateOfPurchase = e.dateOfPurchase;
            dateAddedToRegister = e.dateAddedToRegister;
            addressOfRegistrationOffice = e.addressOfRegistrationOffice;
            geohash = e.geohash;
       
       return (
           entryHash, 
           cadastreID, 
           coordinates, 
           sqmOrSQM, 
           ownedByGoldenAcre, 
           previousOwner, 
           dateOfPurchase, 
           dateAddedToRegister, 
           addressOfRegistrationOffice, 
           geohash
        );
    }
    
    
    function removeSoldLandEntry( uint256 _landEntryID )
        public onlyMinter returns (bool removed)
    {
        EntryInLandRegister storage e = landRecords[_landEntryID];
        

        e.ownedByGoldenAcre = false;
        e.previousOwner = "GoldenAcre";
        
        //ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numEntries -= 1;
        
        uint256 sqmToRemove = e.sqmOrSQM;
        e.sqmOrSQM = 0;
        sqmToken.burn(sqmToRemove, "123", "123");

        return true;
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



