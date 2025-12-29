import Foundation

// Swift-side mtmd type aliases (opaque pointers)
public typealias mtmd_context = OpaquePointer
public typealias mtmd_bitmap = OpaquePointer
public typealias mtmd_input_chunks = OpaquePointer

// llama types used by the mtmd bridge
public typealias llama_pos = Int32
public typealias llama_seq_id = Int32

@_silgen_name("llama_mtmd_is_available")
public func llama_mtmd_is_available() -> Bool

@_silgen_name("llama_mtmd_default_marker")
public func llama_mtmd_default_marker() -> UnsafePointer<CChar>

@_silgen_name("llama_mtmd_create_from_file")
public func llama_mtmd_create_from_file(_ mmprojPath: UnsafePointer<CChar>, _ model: OpaquePointer?, _ nThreads: Int32) -> mtmd_context?

@_silgen_name("llama_mtmd_destroy")
public func llama_mtmd_destroy(_ ctx: mtmd_context?)

@_silgen_name("llama_mtmd_bitmap_create_rgb")
public func llama_mtmd_bitmap_create_rgb(_ data: UnsafePointer<UInt8>?, _ width: UInt32, _ height: UInt32) -> mtmd_bitmap?

@_silgen_name("llama_mtmd_bitmap_destroy")
public func llama_mtmd_bitmap_destroy(_ bitmap: mtmd_bitmap?)

@_silgen_name("llama_mtmd_tokenize_prompt_single")
public func llama_mtmd_tokenize_prompt_single(_ ctx: mtmd_context?, _ prompt: UnsafePointer<CChar>, _ addSpecial: Bool, _ parseSpecial: Bool, _ bitmap: mtmd_bitmap?) -> mtmd_input_chunks?

@_silgen_name("llama_mtmd_eval_chunks")
public func llama_mtmd_eval_chunks(_ ctx: mtmd_context?, _ lctx: OpaquePointer?, _ chunks: mtmd_input_chunks?, _ nPast: llama_pos, _ seqId: llama_seq_id, _ nBatch: Int32, _ logitsLast: Bool, _ newPast: UnsafeMutablePointer<llama_pos>?) -> Int32

@_silgen_name("llama_mtmd_chunks_free")
public func llama_mtmd_chunks_free(_ chunks: mtmd_input_chunks?)
