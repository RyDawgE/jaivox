#import "Basic";

bit_scan_forward :: (mask : u64) -> int { //make this templated later.
    for i: 0..63 {
        if ((mask >> i) & 1) == 1 {
            return i + 1;
        }
    }
    
    return 0;
}