//
//  ViewController.swift
//  WalmartCountries
//
//  Created by Riley Calkins on 4/24/25.
//

import UIKit

struct Country: Codable {
    let name: String
    let region: String
    let code: String
    let capital: String
}

class ViewController: UIViewController {
    private let tableView = UITableView()
    private let searchTextField = UITextField()
    private let searchController = UISearchController(searchResultsController: nil)
    private var allCountries: [Country] = []
    private var displayedCountries: [Country] = []
    private var filteredCountries: [Country] = []
    private var currentPage = 1
    private let pageSize = 20
    private var isLoading = false
    private var hasMoreData = true
    private var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchTextField()
        setupSearchController()
        setupTableView()
        fetchAllCountries()
    }
    
    private func setupSearchTextField() {
        view.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Search by name, code, region or capital"
        searchTextField.borderStyle = .roundedRect
        searchTextField.autocorrectionType = .no
        searchTextField.autocapitalizationType = .none
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name, code, region or capital"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(CountryCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @objc private func searchTextChanged() {
        isSearching = !(searchTextField.text?.isEmpty ?? true)
        filterCountries(for: searchTextField.text ?? "")
        tableView.reloadData()
    }
    
    private func fetchAllCountries() {
        guard !isLoading else { return }
        isLoading = true
        
        let urlString = "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/countries.json"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            }
            
            if let error = error {
                print("Error fetching countries: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                self.allCountries = try JSONDecoder().decode([Country].self, from: data)
                self.loadNextPage()
            } catch {
                print("Error decoding countries: \(error)")
            }
        }.resume()
    }
    
    private func loadNextPage() {
        guard !isSearching else { return }
        
        let startIndex = (currentPage - 1) * pageSize
        let endIndex = min(startIndex + pageSize, allCountries.count)
        
        if startIndex < allCountries.count {
            let newCountries = Array(allCountries[startIndex..<endIndex])
            displayedCountries.append(contentsOf: newCountries)
            hasMoreData = endIndex < allCountries.count
            currentPage += 1
            tableView.reloadData()
        } else {
            hasMoreData = false
        }
    }
    
    private func filterCountries(for searchText: String) {
        guard !searchText.isEmpty else {
            filteredCountries = []
            isSearching = false
            displayedCountries = []
            currentPage = 1
            loadNextPage()
            return
        }
        
        let searchTextLowercased = searchText.lowercased()
        filteredCountries = allCountries.filter { country in
            country.name.lowercased().contains(searchTextLowercased) ||
            country.code.lowercased().contains(searchTextLowercased) ||
            country.region.lowercased().contains(searchTextLowercased) ||
            country.capital.lowercased().contains(searchTextLowercased)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredCountries.count : displayedCountries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as! CountryCell
        let country = isSearching ? filteredCountries[indexPath.row] : displayedCountries[indexPath.row]
        cell.configure(with: country)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isSearching && indexPath.row == displayedCountries.count - 1 && hasMoreData {
            loadNextPage()
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
        filterCountries(for: searchController.searchBar.text ?? "")
        tableView.reloadData()
    }
}

class CountryCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let regionLabel = UILabel()
    private let codeLabel = UILabel()
    private let capitalLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(regionLabel)
        stackView.addArrangedSubview(codeLabel)
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 4
        mainStackView.addArrangedSubview(stackView)
        mainStackView.addArrangedSubview(capitalLabel)
        
        contentView.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        regionLabel.font = .systemFont(ofSize: 14)
        codeLabel.font = .systemFont(ofSize: 14)
        capitalLabel.font = .systemFont(ofSize: 14)
        
        codeLabel.textColor = .gray
    }
    
    func configure(with country: Country) {
        nameLabel.text = country.name
        regionLabel.text = country.region
        codeLabel.text = country.code
        capitalLabel.text = "Capital: \(country.capital)"
    }
}

