import { ethers } from "ethers";

const web3Provider = new ethers.providers.Web3Provider(window.ethereum);

const mockERC20Address = "0xF8e31cb472bc70500f08Cd84917E5A1912Ec8397";
const mockERC721Address = "0xc0F115A19107322cFBf1cDBC7ea011C19EbDB4F8";
const tba = "0xfE5Fa2b6Ac46Ea72fb86c5eF764Ed81B33f5C6cf";

const mockERC20Abi = [
  "function balanceOf(address owner) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
];

// The ERC-20 Contract ABI, which is a common contract interface
// for tokens (this is the Human-Readable ABI format)
const mockERC721Abi = [
  // Get the account balance
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function balanceOf(address owner) view returns (uint256)",
  "function tokenURI(uint256 tokenId) view returns (string memory)",

  // Send some of your tokens to someone else
  "function mintAndCreateAccount(uint tokenId)",
  "function mint(address to, uint256 tokenId)",
];

// The Contract object
const mockERC20 = new ethers.Contract(
  mockERC20Address,
  mockERC20Abi,
  web3Provider
);

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
      const tokenBalance = await mockERC20.balanceOf(tba);
      const tokenURI = await mockERC721.tokenURI(0);

      if (address)
        this.pushEvent("wallet-connected", {
          address: address,
          balance: ethers.utils.formatEther(balance),
          chainId: web3Provider.network.chainId,
          tokenBalance:
            parseFloat(
              ethers.utils.formatEther(tokenBalance.toString()).toString()
            ) / 1.0,
          tokenURI: JSON.parse(atob(tokenURI.slice(29))).image,
        });
    });

    window.addEventListener("phx:connect-wallet", async (e) => {
      const accounts = await web3Provider.provider.request({
        method: "eth_requestAccounts",
      });
      if (accounts.length > 0) {
        const address = accounts[0];
        const balance = await web3Provider.getBalance(address);
        const tokenBalance = await mockERC20.balanceOf(tba);
        const tokenURI = await mockERC721.tokenURI(0);

        // console.log("test", ethers.utils.parseUnits(tokenBalance, "ether"));

        console.log(JSON.parse(atob(tokenURI.slice(29))).image);

        this.pushEvent("wallet-connected", {
          address: address,
          balance: ethers.utils.formatEther(balance),
          chainId: web3Provider.network.chainId,
          tokenBalance:
            parseFloat(
              ethers.utils.formatEther(tokenBalance.toString()).toString()
            ) / 1.0,
          tokenURI: JSON.parse(atob(tokenURI.slice(29))).image,
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

    window.addEventListener("phx:support-fan", async (e) => {
      const signer = await web3Provider.getSigner();

      const supporting = e.detail.supporting;

      console.log(
        "ether",
        ethers.utils.parseEther(supporting, "ether").toString()
      );

      const tx = await mockERC20
        .connect(signer)
        .transfer(tba, ethers.utils.parseEther(supporting, "ether"));
      // const tx = await mockERC721.connect(signer).mintAndCreateAccount(100);
      await tx.wait();

      const message = `🥳 ${tba} receives ${supporting} fan tokens!`;

      const tokenBalance = await mockERC20.balanceOf(tba);
      const tokenURI = await mockERC721.tokenURI(0);

      this.pushEvent("token-received", {
        message: message,
        tokenBalance:
          parseFloat(
            ethers.utils.formatEther(tokenBalance.toString()).toString()
          ) / 1.0,
        tokenURI: JSON.parse(atob(tokenURI.slice(29))).image,
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
