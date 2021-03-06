import UIKit

enum Settings {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum CellIdentifier: String {
        case accountId
        case environment
        case phone
        case seed
        case telegram
        case tfa
        case biometrics
        case autoAuth
        case verification
        case changePassword
        case termsOfService
        case language
        case licenses
        case fees
        case signOut
        case version
    }
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension Settings.Model {
    
    struct SceneModel {
        var sections: [SectionModel]
        let termsUrl: URL?
        
        init(termsUrl: URL?) {
            self.sections = []
            self.termsUrl = termsUrl
        }
    }
    
    struct SectionModel {
        let title: String
        let cells: [CellModel]
        let description: String
    }
    
    struct CellModel {
        let title: String
        let icon: UIImage
        let cellType: CellType
        var topSeparator: SeparatorStyle
        var bottomSeparator: SeparatorStyle
        let identifier: Settings.CellIdentifier
        
        init(
            title: String,
            icon: UIImage,
            cellType: CellType,
            topSeparator: SeparatorStyle = .none,
            bottomSeparator: SeparatorStyle = .lineWithInset,
            identifier: Settings.CellIdentifier
            ) {
            
            self.title = title
            self.icon = icon
            self.cellType = cellType
            self.topSeparator = topSeparator
            self.bottomSeparator = bottomSeparator
            self.identifier = identifier
        }
    }
    
    struct SectionViewModel {
        let title: String?
        let cells: [CellViewAnyModel]
        let description: String?
    }
}

extension Settings.Model.CellModel {
    
    enum CellType {
        case disclosureCell
        case boolCell(Bool)
        case loading
        case reload
        case text
    }
    
    enum SeparatorStyle {
        case none
        case line
        case lineWithInset
    }
}

// MARK: - Events

extension Settings.Event {
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum SectionsUpdated {
        struct Response {
            var sectionModels: [Settings.Model.SectionModel]
        }
        struct ViewModel {
            var sectionViewModels: [Settings.Model.SectionViewModel]
        }
    }
    
    enum DidSelectCell {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
        }
        struct Response {
            let cellIdentifier: Settings.CellIdentifier
        }
        struct ViewModel {
            let cellIdentifier: Settings.CellIdentifier
        }
    }
    
    enum DidSelectSwitch {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
            let state: Bool
        }
        enum Response {
            case loading
            case loaded
            case succeeded
            case failed(Error)
        }
        enum ViewModel {
            case loading
            case loaded
            case succeeded
            case failed(errorMessage: String)
        }
    }
    
    enum DidSelectAction {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
        }
    }
    
    enum ShowTerms {
        struct Response {
            let url: URL
        }
        
        typealias ViewModel = Response
    }
    
    enum ShowFees {
        struct Response {}
        typealias ViewModel = Response
    }
    
    typealias SignOut = ShowFees
}
