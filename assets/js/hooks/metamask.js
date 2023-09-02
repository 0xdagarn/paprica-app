import { ethers } from "ethers";

const web3Provider = new ethers.providers.Web3Provider(window.ethereum);

export const Metamask = {
  mounted() {
    let signer = web3Provider.getSigner();

    window.addEventListener("load", async () => {
      const address = await signer.getAddress();
      console.log(address);
      if (address) this.pushEvent("wallet-connected", { address: address });
    });

    window.addEventListener("phx:connect-wallet", async (e) => {
      const accounts = await web3Provider.provider.request({
        method: "eth_requestAccounts",
      });
      if (accounts.length > 0)
        this.pushEvent("wallet-connected", { address: accounts[0] });
    });
  },
};
