#import "RingBuffer.h"

@implementation RingBuffer

- (id)initWithData:(NSMutableData*)data {
	if (![super init]) return nil;
	buffer = [data retain];
	return self;
}


- (NSUInteger)freeSpace {
	return (position < tail ? tail - position : (buffer.length - position) + tail) - (tail ? 1 : 0);
}


- (BOOL)appendByte:(uint8_t)byte {
	if (self.freeSpace < 1) return NO;
	((uint8_t*)buffer.mutableBytes)[position++] = byte;
	return YES;
}


- (NSInteger)appendData:(NSData*)value offset:(NSInteger)offset length:(NSInteger)length {
	NSInteger totalWritten = 0;
	const uint8_t *input = value.bytes;
	uint8_t *data = buffer.mutableBytes;
	
	if (position >= tail) {
		totalWritten = MIN(buffer.length - position, length);
		memcpy(data + position, input + offset, totalWritten);
		position += totalWritten;
		if (totalWritten == length) return length;
		length -= totalWritten;
		offset += totalWritten;
	}
	
	NSUInteger freeSpace = self.freeSpace;
	if (!freeSpace) return totalWritten;
	
	if (position == buffer.length) {
		position = 0;
	}
	
	// position < tail
	int32_t written = MIN(freeSpace, length);
	memcpy(data + position, input + offset, written);
	position += written;
	totalWritten += written;
	
	return totalWritten;
}


- (NSInteger)flushToOutputStream:(NSOutputStream*)stream {
	const uint8_t *data = buffer.bytes;
	NSInteger totalWritten = 0;
	
	if (tail > position) {
		NSInteger toWrite = buffer.length - tail;
		totalWritten = [stream write:data + tail maxLength:toWrite];
		if (totalWritten < toWrite) return totalWritten;
		tail += totalWritten;
		if (tail == buffer.length) {
			tail = 0;
		}
	}
	
	if (tail < position) {
		int32_t written = [stream write:data + tail maxLength:position - tail];
		if (written <= 0) return totalWritten;
		totalWritten += written;
		tail += written;
		if (position == buffer.length && tail > 0) {
			position = 0;
		}
		if (tail == buffer.length) {
			tail = 0;
		}
	}
	
	return totalWritten;
}


- (void)dealloc {
	[buffer release];
	[super dealloc];
}

@end
