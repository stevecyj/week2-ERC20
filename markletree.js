const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const whitelistJSON = require("./whitelist");

// 透過 merkletreejs 套件產生 merkle tree
function getMerkle(whiteList) {
  const leafs = whiteList.map((addr) => keccak256(addr));
  return new MerkleTree(leafs, keccak256, { sortPairs: true });
}

const whitelistMerkleTree = getMerkle(whitelistJSON);
// console.log("merkle", whitelistMerkleTree);

// 取得 merkle tree 的 root
const root = whitelistMerkleTree.getRoot();
console.log("root", bufferToBytes32(root));

// 取得 proof
function getProof(address) {
  const leaf = keccak256(address);
  return whitelistMerkleTree.getProof(leaf).map((p) => bufferToBytes32(p.data));
}

console.log("proof", getProof("0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"));

// 驗證 proof
function verify(address) {
  const leaf = keccak256(address);
  const proof = getProof(address);
  return whitelistMerkleTree.verify(proof, leaf, root);
}

console.log("verify", verify("0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"));

// 將 buffer 轉成 bytes32
function bufferToBytes32(buffer) {
  return "0x" + buffer.toString("hex").padStart(64, "0");
}

// ["0x4185420a16a37b042236c4ea218ca030419131dc2008e864ad1e555b5f89ecc3","0x8f671600b1e82181938ec81202994214f7675179e475c81d0400ab4745f7d3ac"]
// ["0x4185420a16a37b042236c4ea218ca030419131dc2008e864ad1e555b5f89ecc3","0x8f671600b1e82181938ec81202994214f7675179e475c81d0400ab4745f7d3ac"]
