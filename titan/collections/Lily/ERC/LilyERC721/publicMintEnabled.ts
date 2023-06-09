import { ethers } from "ethers";
import Ducky from "forge/utility/logging/ducky";

/**
 * Retrieves the public mint status of a contract.
 * @param contract The contract object to retrieve the status from.
 * @returns The public mint status of the contract.
 * @throws If the public mint status could not be retrieved.
 */
const publicMintEnabled = async (contract: ethers.Contract): Promise<boolean> => {
    try {
        const isPublicMintingEnabled = await contract.publicMintEnabled(); // Retrieve the public mint status of the contract.
        Ducky.Debug(__filename, "getPublicMintEnabled", `${await contract.name()}.publicMintEnabled is ${isPublicMintingEnabled}`);
        return isPublicMintingEnabled;
    } catch (error: any) {
        const message = `Could not getPublicMintEnabled for contract at address ${contract.getAddress()}`;
        Ducky.Error(__filename, "getPublicMintEnabled", message);
        throw new Error(message);
    }
}

export default publicMintEnabled