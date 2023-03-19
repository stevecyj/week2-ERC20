// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    /* whitelist
    [
        "0xb8a813833b6032b90a658231e1aa71da1e7ea2ed",
        "0x665E0998e82F0293103C4331534Fd346e270FEc3",
        "0xeDB58E4c8B7911bA899603bE5C404cd504502e43"
    ]
     */
    uint256 public tokenId = 0;
    address public contractOwner; // ERC721 變數衝突

    // 讓 unit256 可以使用 toString()
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        contractOwner = msg.sender;
    }

    // 鑄造
    function mint() external {
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

    // 設定 whitelist
}
