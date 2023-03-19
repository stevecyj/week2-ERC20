// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721, Ownable {
    /* 組員whitelist
    [
        "0xb8a813833b6032b90a658231e1aa71da1e7ea2ed",
        "0x665E0998e82F0293103C4331534Fd346e270FEc3",
        "0xeDB58E4c8B7911bA899603bE5C404cd504502e43"
    ]
     */

    struct Auction {
        uint256 startTime; // 開始時間
        uint256 timeStep; // 每個時間階段
        uint256 startPrice; // 開始價格
        uint256 endPrice; // 結束價格
        uint256 priceStep; // 價格階段
        uint256 stepNumber; // 間隔次數
    }

    uint256 public tokenId = 0;
    uint256 public maxSupply;
    address public contractOwner; // ERC721 變數衝突
    bytes32 public root;
    // uint256 public mintPrice;
    Auction public auction;

    // "50000000000000000" -> 0.05 ether
    // 給前端的資料
    function getAuctionPrice() public view returns (uint256) {
        Auction memory currentAuction = auction;
        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }
        uint256 step = (block.timestamp - currentAuction.startTime) /
            currentAuction.timeStep;
        if (step > currentAuction.stepNumber) {
            step = currentAuction.stepNumber;
        }
        return
            currentAuction.startPrice > step * currentAuction.priceStep
                ? currentAuction.startPrice - step * currentAuction.priceStep
                : currentAuction.endPrice;
    }

    function setAuction(
        uint256 _startTime,
        uint256 _timeStep,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _stepNumber
    ) public onlyOwner {
        auction.startTime = _startTime; // 開始時間
        auction.timeStep = _timeStep; // 5 多久扣一次
        auction.startPrice = _startPrice; // 50000000000000000 起始金額
        auction.endPrice = _endPrice; // 10000000000000000 最後金額
        auction.priceStep = _priceStep; // 10000000000000000 每次扣除多少金額
        auction.stepNumber = _stepNumber; // 5 幾個階段
    }

    // 讓 unit256 可以使用 toString()
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
        // uint256 _mintPrice
    ) ERC721(_name, _symbol) {
        contractOwner = msg.sender;
        maxSupply = _maxSupply;
        // mintPrice = _mintPrice;
    }

    modifier verifyProof(bytes32[] memory proof) {
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid proof"
        );
        _;
    }

    // 檢查總發行量
    modifier maxSupplyNotReached() {
        require(tokenId < maxSupply, "Max supply reached");
        _;
    }

    // function auctionMint() external payable {
    //     require(msg.value >= getAuctionPrice(), "not enough value");
    //     uint256 tokenId = _tokenIds.current();
    //     _mint(msg.sender, tokenId);
    //     _tokenIds.increment();
    // }

    // 付費鑄造(取得荷蘭拍的價格、比較tokenId)
    function mint() external payable maxSupplyNotReached {
        require(msg.value >= getAuctionPrice(), "not enough value");
        tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    // 取得 baseURI
    function _baseURI() internal pure override returns (string memory) {
        // 字串截取到檔名之前
        return
            "https://gateway.pinata.cloud/ipfs/QmPoSFBoMzv2AF4M5ZjaMBuMJCe94owGKwhczJViot8Sfr/";
    }

    // 取得 tokenURI
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }

    // 白名單鑄造
    function whitelistMint(bytes32[] calldata _proof)
        external
        verifyProof(_proof)
        maxSupplyNotReached
    {
        tokenId++;
        _safeMint(msg.sender, tokenId);
    }

    // 確認有通過驗證
    function verify(bytes32[] memory proof) external view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    // 設定 root
    function setRoot(bytes32 _root) external {
        require(msg.sender == contractOwner, "Only owner can set root");
        root = _root;
    }

    // 設定 mintPrice
    // function setMintPrice(uint256 _mintPrice) external onlyOwner {
    //     mintPrice = _mintPrice;
    // }
}
