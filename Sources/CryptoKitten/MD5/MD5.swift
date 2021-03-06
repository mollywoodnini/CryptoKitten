public final class MD5: StreamingHash {
    /// MD5 hashes in blocks of 64 bytes
    public static let blockSize = 64
    
    public static var digestSize = 16
    
    private static let s: [UInt32] = [
        7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
        5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
        4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
        6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
    ]

    /// Creates a new MD5 state capable of hasing a Stream of bytes (like a File) efficiently
    public init(_ s: ByteStream) {
        stream = s
        digest = []
    }

    private var a0: UInt32 = 0x67452301
    private var b0: UInt32 = 0xefcdab89
    private var c0: UInt32 = 0x98badcfe
    private var d0: UInt32 = 0x10325476

    private var stream: ByteStream? = nil
    private var digest: [UInt32]

    private static let k: [UInt32] = [
        0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,
        0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
        0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,
        0x6b901122,0xfd987193,0xa679438e,0x49b40821,
        0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,
        0xd62f105d,0x2441453,0xd8a1e681,0xe7d3fbc8,
        0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,
        0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
        0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,
        0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
        0x289b7ec6,0xeaa127fa,0xd4ef3085,0x4881d05,
        0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
        0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,
        0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
        0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,
        0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391
    ]
    
    internal init() {
        digest = []
    }

    // MARK - Hash Protocol
    
    /// Hashes a message with MD5
    ///
    /// - parameter inputBytes: The data to hash
    ///
    /// - returns: The hashed bytes with a length of 16 bytes
    public static func hash(_ inputBytes: [UInt8]) -> [UInt8] {
        // Append an UInt8 with one bit
        var bytes = inputBytes + [0x80]
        
        // The amount of blocks to process
        var inputBlocks = inputBytes.count / blockSize
        
        // We need to end up with 8 remaining bytes to make a full block
        if inputBytes.count % blockSize != blockSize - 8 {
            inputBlocks += 1
            if inputBytes.count % blockSize > blockSize - 8 {
                inputBlocks += 1
            }
            
            bytes.append(contentsOf: [UInt8](repeating: 0, count: ((inputBlocks * blockSize) - 8) - bytes.count))
        }
        
        bytes.append(contentsOf: bitLength(of: inputBytes.count, reversed: true))
        
        // Create an MD5 instance to store the progress
        let md5 = MD5()
        
        // Loop over the blocks
        for i in 0..<inputBlocks {
            let start = i * blockSize
            let end = (i+1) * blockSize
            
            // Process the block
            md5.process(bytes[start..<end])
        }
        
        // Converts an UInt32 to [UInt8] as littleEndian
        func convert(_ int: UInt32) -> [UInt8] {
            let int = int.littleEndian
            return [
                UInt8(int & 0xff),
                UInt8((int >> 8) & 0xff),
                UInt8((int >> 16) & 0xff),
                UInt8((int >> 24) & 0xff)
            ]
        }
        
        var result = [UInt8]()
        
        result.append(contentsOf: convert(md5.a0))
        result.append(contentsOf: convert(md5.b0))
        result.append(contentsOf: convert(md5.c0))
        result.append(contentsOf: convert(md5.d0))
        
        return result
    }

    /// Hashes all data in the stream chunk-by-chunk with MD5
    ///
    /// - throws: Stream errors
    ///
    /// - returns: The hashed bytes with a length of 16 bytes
    public func hash() throws -> [UInt8] {
        guard let stream = stream else {
            throw HashError.noStreamProvided
        }
        
        var count = 0
        while !stream.closed {
            let slice = try stream.next(MD5.blockSize)

            if stream.closed {
                var bytes = Array(slice)
                count += bytes.count
                if bytes.count > MD5.blockSize - 8 {
                    // if the block is slightly too big, just pad and process
                    bytes.append(contentsOf: [UInt8](repeating: 0, count: MD5.blockSize - bytes.count))

                    process(ArraySlice<UInt8>(bytes))

                    // give an empty block for padding
                    bytes = []
                }

                // pad and process the last block
                // adding the bit length
                bytes.append(0x80)
                bytes.append(contentsOf: [UInt8](repeating: 0, count: (MD5.blockSize - 8) - bytes.count))
                bytes.append(contentsOf: bitLength(of: count, reversed: true))
                process(ArraySlice<UInt8>(bytes))
            } else {
                // if the stream is still open,
                // process as normal
                process(slice)
                count += MD5.blockSize
            }
        }

        // Converts an UInt32 to [UInt8] as littleEndian
        func convert(_ int: UInt32) -> [UInt8] {
            let int = int.littleEndian
            return [
                UInt8(int & 0xff),
                UInt8((int >> 8) & 0xff),
                UInt8((int >> 16) & 0xff),
                UInt8((int >> 24) & 0xff)
            ]
        }
        
        var result = [UInt8]()
        
        result.append(contentsOf: convert(a0))
        result.append(contentsOf: convert(b0))
        result.append(contentsOf: convert(c0))
        result.append(contentsOf: convert(d0))
        
        return result
    }
    
    // MARK: Processing

    /// Used for processing a single chunk of 64 bytes, not a byte more of less and updates the hash variables `a0`, `b0`, `c0` and `d0` appropriately
    private func process(_ bytes: ArraySlice<UInt8>) {
        if bytes.count != MD5.blockSize {
            fatalError("MD5 internal error - invalid block provided with size \(bytes.count)")
        }

        var chunk: [UInt32] = makeUInt32Array(bytes)

        var a = a0
        var b = b0
        var c = c0
        var d = d0

        // Main loop
        for i in 0..<64 {
            var g = 0
            var F: UInt32 = 0

            var temp: UInt32

            switch i {
            case 0..<16:
                F = (b & c) | ((~b) & d)
                g = i
            case 16..<32:
                F = (d & b) | ((~d) & c)
                g = (5 * i + 1) % 16
            case 32..<48:
                F = b ^ c ^ d
                g = (3 * i + 5) % 16
            case 48..<64:
                F = c ^ (b | (~d))
                g = (7 * i) % 16
            default:
                fatalError("Impossible switch")
            }

            temp = d
            d = c
            c = b

            let x = (a &+ F &+ MD5.k[i] &+ chunk[g])
            let c = MD5.s[i]

            b = b &+ leftRotate(x, count: c)
            a = temp
        }

        // Add this chunk's hash to the result
        a0 = a0 &+ a
        b0 = b0 &+ b
        c0 = c0 &+ c
        d0 = d0 &+ d
    }

}
