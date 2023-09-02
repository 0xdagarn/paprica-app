import { ethers } from "ethers";

const web3Provider = new ethers.providers.Web3Provider(window.ethereum);

const mockERC721Address = "0x5f3f1dbd7b74c6b46e8c44f98792a1daf8d69154";

// The ERC-20 Contract ABI, which is a common contract interface
// for tokens (this is the Human-Readable ABI format)
const mockERC721Abi = [
  // Get the account balance
  "function ownerOf(uint256 tokenId) view returns (address)",

  // Send some of your tokens to someone else
  "function mintAndCreateAccount(uint tokenId)",
  "function mint(address to, uint256 tokenId)",
];

// The Contract object
const mockERC721 = new ethers.Contract(
  mockERC721Address,
  mockERC721Abi,
  web3Provider
);

export const Metamask = {
  mounted() {
    const signer = web3Provider.getSigner();

    window.addEventListener("load", async () => {
      const address = await signer.getAddress();
      const balance = await web3Provider.getBalance(address);

      if (address)
        this.pushEvent("wallet-connected", {
          address: address,
          balance: ethers.utils.formatEther(balance),
          chainId: web3Provider.network.chainId,
        });
    });

    window.addEventListener("phx:connect-wallet", async (e) => {
      const accounts = await web3Provider.provider.request({
        method: "eth_requestAccounts",
      });
      if (accounts.length > 0) {
        const address = accounts[0];
        const balance = await web3Provider.getBalance(address);
        this.pushEvent("wallet-connected", {
          address: address,
          balance: ethers.utils.formatEther(balance),
          chainId: web3Provider.network.chainId,
        });
      }
    });

    window.addEventListener("phx:support", async (e) => {
      const signer = await web3Provider.getSigner();

      const supporting = e.detail.supporting;
      console.log("supporting", supporting);

      console.log(
        "ether",
        ethers.utils.parseEther(supporting, "ether").toString()
      );

      const obj = {
        to: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        value: ethers.utils.parseEther(supporting, "ether").toString(),
      };
      const tx = await signer.sendTransaction(obj);
      await tx.wait();

      const address = await signer.getAddress();
      const balance = await web3Provider.getBalance(address);

      const message = `🥳 ${address} sent ${supporting} ETH!`;

      this.pushEvent("eth-sent", {
        message: message,
        balance: ethers.utils.formatEther(balance),
      });
    });

    window.addEventListener("phx:mint-nft", async (e) => {
      const address = await signer.getAddress();
      console.log(address);

      const tx = await mockERC721.connect(signer).mint(address, 101);
      // const tx = await mockERC721.connect(signer).mintAndCreateAccount(100);
      await tx.wait();

      const message = `🎉 Now ${address} is your fan!`;

      this.pushEvent("fan-registered", {
        message: message,
      });
    });
  },
};
