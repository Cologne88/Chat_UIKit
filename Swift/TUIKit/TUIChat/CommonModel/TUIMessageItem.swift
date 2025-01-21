
import Foundation
import UIKit

public enum TUIImageType: Int {
    case origin = 1
    case thumb = 2
    case large = 4
}

// MARK: TUIImageItem

public class TUIImageItem: NSObject {
    /// The inner ID for the image, can be used for external cache key
    public var uuid: String = ""
    
    public var url: String = ""
    
    public var size: CGSize = .zero
    
    public var type: TUIImageType = .origin
}

// MARK: TUIVideoItem

public class TUIVideoItem: NSObject {
    /// The internal ID of the video message, which does not need to be set, is obtained from the video instance pulled by the SDK.
    public var uuid: String = ""
    
    /// The video type - the suffix of the video file - is set when sending a message. For example "mp4".
    public var type: String = ""
    
    /// The video size, no need to set, is obtained from the instance pulled by the SDK.
    public var length: Int = 0
    
    /// Video duration
    public var duration: Int = 0
}

// MARK: TUISnapshotItem

public class TUISnapshotItem: NSObject {
    /// Image ID, internal identifier, can be used for external cache key
    public var uuid: String = ""
    
    /// Cover image type
    public var type: String = ""
    
    /// The size of the cover on the UI.
    public var size: CGSize = .zero
    
    public var length: Int = 0
}
