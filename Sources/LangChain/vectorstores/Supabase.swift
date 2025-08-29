//
//  File.swift
//  
//
//  Created by 顾艳华 on 2023/6/12.
//

import Foundation
import Supabase

struct SearchVectorParams: Codable {
    let query_embedding: [Float]
    let match_count: Int
}
struct DocModel: Encodable, Decodable {
    let content: String?
    let embedding: [Float]
    let metadata: [String: String]
}

public class Supabase: VectorStore {
    let client: SupabaseClient
    let embeddings: Embeddings
    public init(embeddings: Embeddings) {
        self.embeddings = embeddings
        let env = LC.loadEnv()
        client = SupabaseClient(supabaseURL: URL(string: env["SUPABASE_URL"]!)!, supabaseKey: env["SUPABASE_KEY"]!)
    }
    
    public override func similaritySearch(query: String, k: Int) async -> [MatchedModel] {
        let params = SearchVectorParams(query_embedding: await embeddings.embedQuery(text: query), match_count: k)
        do {
            let response: [MatchedModel] = try await client
                .rpc("match_documents", params: params)
                .execute()
                .value
//            print("### RPC Returned: \(response.first!.content!)")
            return response
        } catch {
            print("### RPC Error: \(error)")
            return []
        }
        
    }
    
    public override func addText(text: String, metadata: [String: String]) async {
        let embedding = await embeddings.embedQuery(text: text)
        let insertData = DocModel(content: text, embedding: embedding, metadata: metadata)
        do {
            let _: DocModel = try await client
                .from("documents")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value
//          print("### Save Returned: \(response)")
        } catch {
            print("### Insert Error: \(error)")
        }
    }
}
