// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";

contract NftTemplate is ERC721, Ownable {
    struct NftClass {
        bool transferable;
        bool mintable;
        bool burnable;
        bool frozen;
        address owner;
        uint64 currentIndex;
        uint64 burnedAmount;
        uint64 maxPerTx;
        uint64 maxSupply;
        uint128 price;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
    }

    uint256 public nextTokenId = 0;

    uint256 public nextClassId = 0;

    // Mapping class id to class data
    mapping(uint256 => NftClass) private _classData;

    // Mapping token ID to Class Id
    mapping(uint256 => uint256) private _tokenClass;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
        
    }

    function addNftClass(
        bool _transferable,
        bool _mintable,
        bool _burnable,
        bool _frozen,
        address _owner,
        uint64 _maxPerTx,
        uint64 _maxSupply,
        uint128 _price
    ) external onlyOwner {
        NftClass storage class = _classData[nextClassId++];
        class.transferable = _transferable;
        class.mintable = _mintable;
        class.burnable = _burnable;
        class.frozen = _frozen;
        class.owner = _owner;
        class.currentIndex = 0;
        class.burnedAmount = 0;
        class.maxPerTx = _maxPerTx;
        class.maxSupply = _maxSupply;
        class.price = _price;
    }

    modifier isOwnerOfClass(uint256 _classId) {
        require(_classData[_classId].owner == msg.sender);
        _;
    }

    modifier isClassFrozen(uint256 _classId) {
        require(!_classData[_classId].frozen, "Class has been frozen!");
        _;
    }

    modifier validClassId(uint256 _classId) {
        require(_classId < nextClassId, "Invalid class id!");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount, uint256 _classId) {
        require(
            totalSupplyOfClass(_classId) + _mintAmount <=
                _classData[_classId].maxSupply,
            "Max supply exceed!"
        );
        require(
            _mintAmount <= _classData[_classId].maxPerTx,
            "Can not mint this many!"
        );
        require(
            msg.value == _mintAmount * _classData[_classId].price,
            "Wrong amount of ether!"
        );
        _;
    }

    function mint(uint256 _mintAmount, uint256 _classId)
        public
        payable
        validClassId(_classId)
        mintCompliance(_mintAmount, _classId)
    {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, nextTokenId++);
        }
        _classData[_classId].currentIndex += uint64(_mintAmount);
    }

    function totalSupply() public view returns (uint256) {
        uint256 total;
        unchecked {
            for (uint256 i = 0; i < nextClassId; i++) {
                total =
                    total +
                    _classData[i].currentIndex -
                    _classData[i].burnedAmount;
            }
            return total;
        }
    }

    function totalSupplyOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        unchecked {
            return
                _classData[_classId].currentIndex -
                _classData[_classId].burnedAmount;
        }
    }

    function setOwnerOfClass(uint256 _classId, address _newOwner)
        external
        validClassId(_classId)
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "Can't set ownership to zero address!"
        );
        _classData[_classId].owner = _newOwner;
    }

    function freezeClass(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
    {
        _classData[_classId].frozen = true;
    }

    function flipTransferable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].transferable = !_classData[_classId].transferable;
    }

    function flipBurnable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].burnable = !_classData[_classId].burnable;
    }

    function flipMintable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].mintable = !_classData[_classId].mintable;
    }

    function setMaxSupplyOfClass(uint256 _classId, uint64 _newMaxSupply)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].maxSupply = _newMaxSupply;
    }

    function setPriceOfClass(uint256 _classId, uint128 _newPrice)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].price = _newPrice;
    }

    function setMaxPerTxOfClass(uint256 _classId, uint64 _newMaxPerTx)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].maxPerTx = _newMaxPerTx;
    }

    function getCurrentSupplyOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        return _classData[_classId].currentIndex;
    }

    function getMaxSupplyOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        return _classData[_classId].maxSupply;
    }

    function getPriceOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        return _classData[_classId].price;
    }

    function isTransferable(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (bool)
    {
        return _classData[_classId].transferable;
    }

    function isMintable(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (bool)
    {
        return _classData[_classId].mintable;
    }

    function isBurnable(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (bool)
    {
        return _classData[_classId].burnable;
    }

    function isFrozen(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (bool)
    {
        return _classData[_classId].frozen;
    }
}
