#include "../UserModel.hpp"
#include <iostream>
#include <chrono>

using namespace openstudio::isomodel;

int main(int argc, char** argv)
{
  if (argc < 2) {
    std::cout << "Usage: isomodel_unit_tests test_data_directory" << std::endl;
    std::cout << "Running with default directory." << std::endl;

    UserModel userModel;
    userModel.load("../test_data/SmallOffice_v2.ism");
    auto simModel = userModel.toSimModel();
    auto monthlyResults = simModel.simulate();

    std::cout << "Finished simulation" << std::endl;

  } else {
    std::string test_data_path = argv[argc - 1];

    // Set up the hourly and monthly models.
    UserModel userModel;

    std::cout << "loading test data from: " << test_data_path << std::endl;
    userModel.load(test_data_path + "/SmallOffice_v2.ism");

    std::cout << "Creating SimModel" << std::endl;
    SimModel simModel = userModel.toSimModel();
    
    std::cout << "Creating HourlyModel" << std::endl;
    ISOHourly hourlyModel = userModel.toHourlyModel();


    // Number of iterations to run for each benchmark.
    int iterations = 10;

    // Benchmark the monthly simulation.
    std::cout << "Running Monthly Simulation" << std::endl;

    ISOResults monthlyResults;
    auto monthStart = std::chrono::steady_clock::now();
    for (int i = 0; i != iterations; ++i){
      monthlyResults = simModel.simulate();
    }
    auto monthEnd = std::chrono::steady_clock::now();

    auto monthDiff = monthEnd - monthStart;
    double monthlyTime = std::chrono::duration<double, std::micro>(monthDiff).count() / iterations;
    std::cout << "Monthly simulation ran in " << monthlyTime << " us, average over " << iterations << " loops." << std::endl;

    // Benchmark the hourly simulation.
    std::cout << "Running Hourly Simulation" << std::endl;
    
    ISOResults hourlyResults;
    auto hourStart = std::chrono::steady_clock::now();
    for (int i = 0; i != iterations; ++i){
      hourlyResults = hourlyModel.simulate();
    }
    auto hourEnd = std::chrono::steady_clock::now(); 

    auto hourDiff = hourEnd - hourStart;
    double hourlyTime = std::chrono::duration<double, std::micro>(hourDiff).count() / iterations;
    std::cout << "Hourly simulation ran in " << hourlyTime << " us, average over " << iterations << " loops." << std::endl;

    std::cout << "Benchmarking full monthly simulation including loading data.\n";
    auto monthWithLoadStart = std::chrono::steady_clock::now();
    for (int i = 0; i != iterations; ++i){
      UserModel userModel2{};
      userModel2.load(test_data_path + "/SmallOffice_v2.ism");
      auto simModel2 = userModel2.toSimModel();
      auto monthlyResults = simModel2.simulate();
    }
    auto monthWithLoadEnd = std::chrono::steady_clock::now();

    auto monthWithLoadDiff = monthWithLoadEnd - monthWithLoadStart;
    double monthlyTimeWithLoad = std::chrono::duration<double, std::micro>(monthWithLoadDiff).count() / iterations;
    std::cout << "Monthly simulation including loading data ran in " << monthlyTimeWithLoad << " us, average over " << iterations << " loops." << std::endl;

    std::cout << "Done!" << std::endl;
  }
}

