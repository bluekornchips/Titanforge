import { activeClient } from "forge/prisma/prismaClient";
import { contracts_db } from "forge/types";

/**
 * @dev Gets all contracts from PostgreSQL
 * @return A Promise resolving to an array of contracts
 * @throws If there is an error getting the contracts from PostgreSQL or if there are no contracts in the database
 */
const get = async (): Promise<contracts_db[]> => {
    const contract_response = await activeClient.contracts.findMany()

    if (!contract_response || contract_response.length === 0) {
        throw new Error(`Could not find any contracts in PostgreSQL`);
    }

    return contract_response;
}

export default get;