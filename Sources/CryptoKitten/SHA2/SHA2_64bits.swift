internal protocol SHA2_64bits: class, StreamingHash {
    var hashCode: [UInt64] { get set }
    var k: [UInt64] { get }
    
    init()
}

extension SHA2_64bits {
    /// Used for processing a single chunk of 128 bytes, not a byte more of less and updates the `hashCode` appropriately
    internal func process(_ chunk: ArraySlice<UInt8>) {
        if chunk.count != Self.blockSize {
            fatalError("SHA1 internal error - invalid block provided with size \(chunk.count)")
        }
        
        func rightRotate(_ number: UInt64, amount: UInt64) -> UInt64 {
            return (number >> amount) | (number << (64 - amount))
        }
        
        // break chunk into sixteen 64-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 64-bit words into sixty-four 32-bit words:
        var w = [UInt64](repeating: 0, count: k.count)
        for i in 0..<w.count {
            switch (i) {
            case 0...15:
                let start = chunk.startIndex + (i * MemoryLayout.size(ofValue: w[i]))
                let end = start + 8
                let word = UInt64(chunk[start..<end])
                w[i] = word.bigEndian
                break
            default:
                let s0 = rightRotate(w[i - 15], amount: 1) ^ rightRotate(w[i - 15], amount: 8) ^ (w[i - 15] >> 7)
                let s1 = rightRotate(w[i - 2], amount: 19) ^ rightRotate(w[i - 2], amount: 61) ^ (w[i - 2] >> 6)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
                break
            }
        }
        
        var a = hashCode[0]
        var b = hashCode[1]
        var c = hashCode[2]
        var d = hashCode[3]
        var e = hashCode[4]
        var f = hashCode[5]
        var g = hashCode[6]
        var h = hashCode[7]
        
        // Compression function Main loop
        for i in 0..<k.count {
            let S1 = rightRotate(e, amount: 14) ^ rightRotate(e, amount: 18) ^ rightRotate(e, amount: 41)
            let ch = (e & f) ^ ((~e) & g)
            let temp1 = h &+ S1 &+ ch &+ k[i] &+ w[i]
            let S0 = rightRotate(a, amount: 28) ^ rightRotate(a, amount: 34) ^ rightRotate(a, amount: 39)
            let maj = (a & b) ^ (a & c) ^ (b & c)
            let temp2 = S0 &+ maj
            
            h = g
            g = f
            f = e
            e = d &+ temp1
            d = c
            c = b
            b = a
            a = temp1 &+ temp2
        }
        
        // Add compressed chunk to the hash value
        hashCode = [
            (hashCode[0] &+ a),
            (hashCode[1] &+ b),
            (hashCode[2] &+ c),
            (hashCode[3] &+ d),
            (hashCode[4] &+ e),
            (hashCode[5] &+ f),
            (hashCode[6] &+ g),
            (hashCode[7] &+ h)
        ]
    }
}

public final class SHA384: SHA2_64bits {
    internal init() { }
    
    private var stream: ByteStream? = nil
    
    public init(_ s: ByteStream) {
        stream = s
    }
    
    public static var blockSize = 128
    public static var digestSize = 48
    
    internal var hashCode: [UInt64] = [
        0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939, 0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4
    ]
    
    internal let k: [UInt64] = [
        0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538,
        0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe,
        0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
        0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
        0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,
        0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
        0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed,
        0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
        0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
        0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53,
        0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373,
        0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
        0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c,
        0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6,
        0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
        0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
    ]
    
    /// Hashes a message with SHA384
    ///
    /// - parameter inputBytes: The data to hash
    ///
    /// - returns: The hashed bytes with a length of 48 bytes
    public static func hash(_ inputBytes: [UInt8]) -> [UInt8] {
        var bytes = inputBytes + [0x80]
        var inputBlocks = inputBytes.count / blockSize
        
        if inputBytes.count % blockSize != blockSize - 8 {
            inputBlocks += 1
            if inputBytes.count % blockSize > blockSize - 8 {
                inputBlocks += 1
            }
            
            bytes.append(contentsOf: [UInt8](repeating: 0, count: ((inputBlocks * blockSize) - 8) - bytes.count))
        }
        
        bytes.append(contentsOf: bitLength(of: inputBytes.count, reversed: false))
        
        let sha2 = SHA384()
        
        for i in 0..<inputBlocks {
            let start = i * blockSize
            let end = (i+1) * blockSize
            sha2.process(bytes[start..<end])
        }
        
        var resultBytes = [UInt8]()
        
        for hashPart in sha2.hashCode[0...5] {
            // Big Endian is required
            let hashPart = hashPart.bigEndian
            resultBytes += [UInt8(hashPart & 0xff), UInt8((hashPart >> 8) & 0xff), UInt8((hashPart >> 16) & 0xff), UInt8((hashPart >> 24) & 0xff), UInt8((hashPart >> 32) & 0xff), UInt8((hashPart >> 40) & 0xff), UInt8((hashPart >> 48) & 0xff), UInt8((hashPart >> 56) & 0xff)]
        }
        
        return resultBytes
    }
    
    /// Hashes all data in the provided stream chunk-by-chunk with SHA384
    ///
    /// - throws: Stream errors
    ///
    /// - returns: The hashed bytes with a length of 48 bytes
    public func hash() throws -> [UInt8] {
        guard let stream = stream else {
            throw HashError.noStreamProvided
        }
        
        var count = 0
        while !stream.closed {
            let slice = try stream.next(SHA384.blockSize)
            
            if stream.closed {
                var bytes = Array(slice)
                if bytes.count > SHA384.blockSize - 8 {
                    // if the block is slightly too big, just pad and process
                    bytes.append(contentsOf: [UInt8](repeating: 0, count: SHA384.blockSize - bytes.count))
                    
                    process(ArraySlice<UInt8>(bytes))
                    count += bytes.count
                    
                    // give an empty block for padding
                    bytes = []
                } else {
                    // add this block's count to the total
                    count += bytes.count
                }
                
                // pad and process the last block
                // adding the bit length
                bytes.append(0x80)
                bytes.append(contentsOf: [UInt8](repeating: 0, count: (SHA384.blockSize - 8) - bytes.count))
                bytes.append(contentsOf: bitLength(of: count, reversed: false))
                process(ArraySlice<UInt8>(bytes))
            } else {
                // if the stream is still open,
                // process as normal
                process(slice)
                count += SHA384.blockSize
            }
        }
        
        var resultBytes = [UInt8]()
        
        for hashPart in hashCode[0...5] {
            // Big Endian is required
            let hashPart = hashPart.bigEndian
            resultBytes += [UInt8(hashPart & 0xff), UInt8((hashPart >> 8) & 0xff), UInt8((hashPart >> 16) & 0xff), UInt8((hashPart >> 24) & 0xff), UInt8((hashPart >> 32) & 0xff), UInt8((hashPart >> 40) & 0xff), UInt8((hashPart >> 48) & 0xff), UInt8((hashPart >> 56) & 0xff)]
        }
        
        return resultBytes
    }
}

public final class SHA512: SHA2_64bits {
    internal init() { }
    
    private var stream: ByteStream? = nil
    
    public init(_ s: ByteStream) {
        stream = s
    }
    
    public static var blockSize = 128
    public static var digestSize = 64
    
    internal var hashCode: [UInt64] = [
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
        0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
    ]
    
    internal let k: [UInt64] = [
        0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538,
        0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe,
        0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
        0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
        0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,
        0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
        0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed,
        0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
        0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
        0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53,
        0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373,
        0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
        0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c,
        0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6,
        0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
        0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
    ]
    
    /// Hashes a message with SHA512
    ///
    /// - parameter inputBytes: The data to hash
    ///
    /// - returns: The hashed bytes with a length of 64 bytes
    public static func hash(_ inputBytes: [UInt8]) -> [UInt8] {
        var bytes = inputBytes + [0x80]
        var inputBlocks = inputBytes.count / blockSize
        
        if inputBytes.count % blockSize != blockSize - 8 {
            inputBlocks += 1
            if inputBytes.count % blockSize > blockSize - 8 {
                inputBlocks += 1
            }
            
            bytes.append(contentsOf: [UInt8](repeating: 0, count: ((inputBlocks * blockSize) - 8) - bytes.count))
        }
        
        bytes.append(contentsOf: bitLength(of: inputBytes.count, reversed: false))
        
        let sha2 = SHA512()
        
        for i in 0..<inputBlocks {
            let start = i * blockSize
            let end = (i+1) * blockSize
            sha2.process(bytes[start..<end])
        }
        
        // Return the resulting bytes
        var resultBytes = [UInt8]()
        
        for hashPart in sha2.hashCode {
            // Big Endian is required
            let hashPart = hashPart.bigEndian
            resultBytes += [UInt8(hashPart & 0xff), UInt8((hashPart >> 8) & 0xff), UInt8((hashPart >> 16) & 0xff), UInt8((hashPart >> 24) & 0xff), UInt8((hashPart >> 32) & 0xff), UInt8((hashPart >> 40) & 0xff), UInt8((hashPart >> 48) & 0xff), UInt8((hashPart >> 56) & 0xff)]
        }
        
        return resultBytes
    }
    
    /// Hashes all data in the provided stream chunk-by-chunk with SHA512
    ///
    /// - throws: Stream errors
    ///
    /// - returns: The hashed bytes with a length of 64 bytes
    public func hash() throws -> [UInt8] {
        guard let stream = stream else {
            throw HashError.noStreamProvided
        }
        
        var count = 0
        while !stream.closed {
            let slice = try stream.next(SHA512.blockSize)
            
            if stream.closed {
                var bytes = Array(slice)
                if bytes.count > SHA512.blockSize - 8 {
                    // if the block is slightly too big, just pad and process
                    bytes.append(contentsOf: [UInt8](repeating: 0, count: SHA512.blockSize - bytes.count))
                    
                    process(ArraySlice<UInt8>(bytes))
                    count += bytes.count
                    
                    // give an empty block for padding
                    bytes = []
                } else {
                    // add this block's count to the total
                    count += bytes.count
                }
                
                // pad and process the last block
                // adding the bit length
                bytes.append(0x80)
                bytes.append(contentsOf: [UInt8](repeating: 0, count: (SHA512.blockSize - 8) - bytes.count))
                bytes.append(contentsOf: bitLength(of: count, reversed: false))
                process(ArraySlice<UInt8>(bytes))
            } else {
                // if the stream is still open,
                // process as normal
                process(slice)
                count += SHA512.blockSize
            }
        }
        
        // Return the resulting bytes
        var resultBytes = [UInt8]()
        
        for hashPart in hashCode {
            // Big Endian is required
            let hashPart = hashPart.bigEndian
            resultBytes += [UInt8(hashPart & 0xff), UInt8((hashPart >> 8) & 0xff), UInt8((hashPart >> 16) & 0xff), UInt8((hashPart >> 24) & 0xff), UInt8((hashPart >> 32) & 0xff), UInt8((hashPart >> 40) & 0xff), UInt8((hashPart >> 48) & 0xff), UInt8((hashPart >> 56) & 0xff)]
        }
        
        return resultBytes
    }
}
