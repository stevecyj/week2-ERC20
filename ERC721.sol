// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyNFT is ERC721, Ownable {
    /* 組員whitelist
    [
        "0xb8a813833b6032b90a658231e1aa71da1e7ea2ed",
        "0x665E0998e82F0293103C4331534Fd346e270FEc3",
        "0xeDB58E4c8B7911bA899603bE5C404cd504502e43"
    ]
     */
    uint256 public tokenId = 0;
    uint256 public maxSupply;
    address public contractOwner; // ERC721 變數衝突
    bytes32 public root;
    uint256 public mintPrice;

    // 讓 unit256 可以使用 toString()
    using Strings for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC721(_name, _symbol) {
        contractOwner = msg.sender;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
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

    // 付費鑄造
    function mint() external payable {
        require(tokenId < maxSupply, "Max supply reached");
        require(msg.value == mintPrice, "Incorrect amount sent");
        tokenId++;
        _safeMint(msg.sender, tokenId);
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
    {
        require(tokenId < maxSupply, "Max supply reached");
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
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
}
