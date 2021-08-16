//
//  UserTableViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialSnackbar

class LocationsTableViewController: UITableViewController {
    
    var actionsDelegate: UserActionsDelegate?;
    var scheme: MDCContainerScheming?;
    var updateTimer: Timer?;
    var listenersSetUp = false;
    var userIds: [String]?;
    
    private lazy var allReturned : UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30));
        label.textAlignment = .center;
        label.text = "All users have been returned."
        return label;
    }()
    
    public lazy var locationDataStore: LocationDataStore = {
        if (self.actionsDelegate == nil) {
            actionsDelegate = self;
        }

        let locationDataStore = LocationDataStore(tableView: tableView, actionsDelegate: actionsDelegate, scheme: scheme);
        return locationDataStore;
    }()
    
    private lazy var userDataStore: UserDataStore = {
        if (self.actionsDelegate == nil) {
            actionsDelegate = self;
        }
        
        let userDataStore = UserDataStore(tableView: tableView, userIds: userIds, actionsDelegate: actionsDelegate, scheme: scheme);
        return userDataStore;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(userIds: [String]? = nil, actionsDelegate: UserActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(style: .grouped);
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        self.userIds = userIds;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.tableView.separatorStyle = .none;
        
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : containerScheme.colorScheme.onPrimaryColor];
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor];
        let appearance = UINavigationBarAppearance();
        appearance.configureWithOpaqueBackground();
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor
        ];
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor:  containerScheme.colorScheme.onPrimaryColor
        ];
        
        self.navigationController?.navigationBar.standardAppearance = appearance;
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        
        self.navigationItem.titleLabel?.textColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationItem.subtitleLabel?.textColor = containerScheme.colorScheme.onPrimaryColor;
        
        self.navigationController?.navigationBar.prefersLargeTitles = false;
        
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh users", attributes: [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onBackgroundColor])
        refreshControl?.tintColor = containerScheme.colorScheme.onBackgroundColor;
        
        allReturned.font = containerScheme.typographyScheme.caption;
        allReturned.textColor = containerScheme.colorScheme.onBackgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.tableView.backgroundView = nil;
        self.tableView.register(cellClass: PersonTableViewCell.self)
        self.tableView.register(UINib(nibName: "TableSectionHeader", bundle: nil), forCellReuseIdentifier: "TableSectionHeader");
        
        if (userIds == nil) {
            self.refreshControl = UIRefreshControl();
            refreshControl?.addTarget(self, action: #selector(refreshLocations), for: .valueChanged);
            self.tableView.refreshControl = self.refreshControl;
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filterButtonPressed));
        }
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.estimatedRowHeight = 155;
        self.tableView.contentInset.bottom = 100;
        self.tableView.tableFooterView = allReturned;
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setupFilterListeners() {
        UserDefaults.standard.addObserver(self, forKeyPath: kLocationTimeFilterKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kLocationTimeFilterNumberKey, options: .new, context: nil);
        UserDefaults.standard.addObserver(self, forKeyPath: kLocationTimeFilterUnitKey, options: .new, context: nil);
        listenersSetUp = true;
    }
    
    func removeFilterListeners() {
        if (listenersSetUp) {
            UserDefaults.standard.removeObserver(self, forKeyPath: kLocationTimeFilterKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kLocationTimeFilterNumberKey, context: nil);
            UserDefaults.standard.removeObserver(self, forKeyPath: kLocationTimeFilterUnitKey, context: nil);
        }
        listenersSetUp = false;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // iOS bug fix.
        // For some reason the first view in a TabBarViewController when that TabBarViewController
        // is the master view of a split view the toolbar will not attach to the status bar correctly.
        // Forcing it to relayout seems to fix the issue.
        self.view.setNeedsLayout();
        
        self.applyTheme(withContainerScheme: self.scheme);
        
        if (userIds == nil) {
            setupFilterListeners();
            self.setNavBarTitle();
            self.startUpdateTimer();
            locationDataStore.startFetchController();
        } else {
            userDataStore.startFetchController(userIds: userIds);
        }
        self.tableView.reloadData();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        if (userIds == nil) {
            self.stopUpdateTimer();
            self.locationDataStore.locations?.delegate = nil;
            removeFilterListeners();
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        if (userIds == nil) {
            self.startUpdateTimer();
        }
    }
    
    func startUpdateTimer() {
        if (self.updateTimer != nil) {
            return;
        }
        self.updateTimer = Timer(timeInterval: 60, target: self, selector: #selector(onUpdateTimerFire), userInfo: nil, repeats: true);
        RunLoop.main.add(self.updateTimer!, forMode: .default);
        self.locationDataStore.updatePredicates();
    }
    
    func stopUpdateTimer() {
        guard let timer = self.updateTimer else { return }
        timer.invalidate();
        self.updateTimer = nil;
    }
    
    @objc func onUpdateTimerFire() {
        self.locationDataStore.updatePredicates();
    }
    
    func setNavBarTitle() {
        let timeFilterString = MageFilter.getString();
        self.navigationItem.setTitle("People", subtitle: (timeFilterString == "All" ? nil : timeFilterString), scheme: self.scheme);
    }
    
    @objc func filterButtonPressed() {
        let filterStoryboard = UIStoryboard(name: "Filter", bundle: nil);
        let fvc: LocationFilterTableViewController = filterStoryboard.instantiateViewController(identifier: "locationFilter");
        fvc.applyTheme(withContainerScheme: self.scheme);
        self.navigationController?.pushViewController(fvc, animated: true);
    }
    
    @objc func refreshLocations() {
        refreshControl?.beginRefreshing();
        let locationFetchTask: URLSessionDataTask = Location.operationToPullLocations {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        } failure: { (_) in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing();
            }
        }
        MageSessionManager.shared()?.addTask(locationFetchTask);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == kLocationTimeFilterKey || keyPath == kLocationTimeFilterNumberKey || keyPath == kLocationTimeFilterUnitKey) {
            self.locationDataStore.updatePredicates();
            setNavBarTitle();
        }
    }
}

extension LocationsTableViewController: UserActionsDelegate {
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    func viewUser(_ user: User) {
        let uvc = UserViewController(user: user, scheme: self.scheme!);
        self.navigationController?.pushViewController(uvc, animated: true);
    }
    
    func getDirectionsToUser(_ user: User) {
        guard let location: CLLocationCoordinate2D = user.location?.location().coordinate else {
            return;
        }
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            
            var image: UIImage? = UIImage(named: "me")
            if let safeIconUrl = user.iconUrl {
                if (safeIconUrl.lowercased().hasPrefix("http")) {
                    let token = StoredPassword.retrieveStoredToken();
                    do {
                        try image = UIImage(data: Data(contentsOf: URL(string: "\(safeIconUrl)?access_token=\(token ?? "")")!))
                    } catch {
                        // whatever
                    }
                } else {
                    do {
                        try image = UIImage(data: Data(contentsOf: URL(fileURLWithPath: "\(self.getDocumentsDirectory())/\(safeIconUrl)")))
                    } catch {
                        // whatever
                    }
                }
                let scale = image?.size.width ?? 0.0 / 37;
                image = UIImage(cgImage: image!.cgImage!, scale: scale, orientation: image!.imageOrientation);
            }
            
            if let nvc: UINavigationController = self.tabBarController?.viewControllers?.filter( {
                vc in
                if let navController = vc as? UINavigationController {
                    return navController.viewControllers[0] is MapViewController
                }
                return false;
            }).first as? UINavigationController {
                nvc.popToRootViewController(animated: false);
                self.tabBarController?.selectedViewController = nvc;
                if let mvc: MapViewController = nvc.viewControllers[0] as? MapViewController {
                    mvc.mapDelegate.userToNavigateTo = user;
                    mvc.mapDelegate.startStraightLineNavigation(location, image: image);
                }
            }
        }));
        ObservationActionHandler.getDirections(latitude: location.latitude, longitude: location.longitude, title: user.name ?? "User", viewController: self.navigationController!, extraActions: extraActions);
    }
}