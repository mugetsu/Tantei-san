//
//  DashboardView.swift
//  Tantei-san
//
//  Created by Randell on 1/10/22.
//

import UIKit
import SnapKit

class DashboardView: UIViewController, DashboardBaseCoordinated {
    private let viewModel: DashboardViewModel
    var coordinator: DashboardBaseCoordinator?
    
    private lazy var topAnimeView: SwipeableCardsView = {
        let swipeableCardsView = SwipeableCardsView()
        swipeableCardsView.cardSpacing = 8
        swipeableCardsView.insets = UIEdgeInsets(
            top: 8,
            left: 8,
            bottom: 8,
            right: 8
        )
        return swipeableCardsView
    }()
    
    required init(viewModel: DashboardViewModel, coordinator: DashboardBaseCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.Custom.thin?.withSize(21)
        label.textColor = .white
        label.text = "'Sup"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureView()
        viewModel.getTopAnimes(type: .tv, filter: .airing)
    }
}

// MARK: UI Setup
private extension DashboardView {
    func setupNavigation() {
        navigationItem.title = "Hello"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func configureView() {
        view.backgroundColor = UIColor.Elements.backgroundLight
    }
    
    func configureLayout() {}
}

// MARK: SwipeableCardsViewDelegate
extension DashboardView: SwipeableCardsViewDataSource, SwipeableCardsViewDelegate {
    func swipeableCardsNumberOfItems(_ collectionView: SwipeableCardsView) -> Int {
        return viewModel.numberOfItems
    }

    func swipeableCardsView(_: SwipeableCardsView, viewForIndex index: Int) -> SwipeableCard {
        let view = SwipeableCard()
        let label = UILabel()
        let anime = viewModel.getAnime(for: index)
        print("anime: \(anime)")
        guard let titles = anime.titles?.first(where: {
            $0.type == "English" || $0.type == "Default"
        }) else {
            return view
        }
        view.backgroundColor = UIColor.Illustration.highlight
        label.text = "\(titles.title)"
        view.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        return view
    }
    
    func swipeableCardsView(_: SwipeableCardsView, didSelectItemAtIndex index: Int) {
        print("A view with index \(index) was selected.")
    }
}

// MARK: RequestDelegate
extension DashboardView: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                break
            case .success:
                self.updateView()
            case .error(let error):
                print(error)
            }
        }
    }
    
    func updateView() {
        topAnimeView.dataSource = self
        topAnimeView.delegate = self
        view.addSubview(topAnimeView)
        topAnimeView.snp.makeConstraints {
            $0.height.equalTo(320)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.equalTo(view.safeAreaLayoutGuide)
            $0.right.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
