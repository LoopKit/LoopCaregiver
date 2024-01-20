//
//  OverrideViewModelTests.swift
//  LoopCaregiverTests
//
//  Created by Bill Gestrich on 10/1/23.
//

import Combine
@testable import LoopCaregiver
import NightscoutKit
import XCTest

final class OverrideViewModelTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
    
    //MARK: Loading States
    
    func testLoading_OverrideActive_SelectsOverride() async throws {
        
        //Arrange

        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let activeOverride = presets.last!
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        XCTAssertEqual(viewModel.pickerSelectedRow?.name, activeOverride.name)
    }
    
    func testLoading_OverridesInactive_SelectsNoOverride() async throws {
        
        //Arrange

        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        XCTAssertNil(viewModel.activeOverride)
    }
    
    func testLoading_WhenSuccessful_HasCompleteState() async throws {
        
        //Arrange
        
        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        switch viewModel.overrideListState{
        case .loadingComplete(let resultingOverrideState):
            XCTAssertEqual(resultingOverrideState, overrideState)
        default:
            XCTFail("Wrong case")
        }
    }
    
    func testLoading_WhenErrorOccurs_HasErrorState() async throws {
        
        //Arrange
        
        let loadingError = OverrideViewDelegateMock.MockError.NetworkError
        let delegate = OverrideViewDelegateMock(mockState: .error(loadingError))
        let viewModel = OverrideViewModel()
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        switch viewModel.overrideListState{
        case .loadingError(let err):
            XCTAssertEqual(err.localizedDescription, loadingError.localizedDescription)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertNil(viewModel.pickerSelectedRow)
    }
    
    func testLoading_WhileLoading_HasLoadingState() async throws {
        
        //Arrange
        
        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let overrideState = OverrideState(activeOverride: nil, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        var progressWasLoading = false
        
        let _ = viewModel.$overrideListState.sink { val in
            switch val {
            case .loading:
                progressWasLoading = true
            default:
                break
            }
        }
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        XCTAssertTrue(progressWasLoading)
    }
    
    
    //MARK: Enabled Button
    
    func testPickerChanged_NoActiveOverride_EnablesUpdateButton() async throws {
        
        //Arrange

        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let activeOverride = presets[1]
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        let selectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: activeOverride)
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        viewModel.pickerSelectedRow = selectedRow
        
        //Assert
        
        switch viewModel.overrideListState{
        case .loadingComplete(let loadedState):
            XCTAssertEqual(loadedState, overrideState)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertTrue(viewModel.pickerSelectedRow == selectedRow)

    }

    func testPickerChanged_ActiveOverride_DisablesUpdateButton() async throws {
        
        //Arrange

        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let activeOverride = presets[0]
        let overrideState = OverrideState(activeOverride: activeOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        //Act
        
        await viewModel.setup(delegate: delegate, deliveryCompleted: nil)
        
        //Assert
        
        switch viewModel.overrideListState{
        case .loadingComplete(let loadedState):
            XCTAssertEqual(loadedState, overrideState)
        default:
            XCTFail("Wrong case")
        }
        XCTAssertTrue(viewModel.pickerSelectedRow?.name == viewModel.activeOverride?.name)

    }


    //MARK: Delivery

    
    func testDeliver_WhenValid_Succeeds() async throws {
        
        //Arrange
        
        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let initialActiveOverride = presets[0]
        let overrideState = OverrideState(activeOverride: initialActiveOverride, presets: presets)
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState))
        let viewModel = OverrideViewModel()
        
        //Act
        
        var deliveryCompletionCalled = false
        await viewModel.setup(delegate: delegate, deliveryCompleted: {deliveryCompletionCalled = true})
        let updatedActiveOverride = presets[1]
        viewModel.pickerSelectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: updatedActiveOverride)
        await viewModel.updateButtonTapped()
        
        //Assert
        
        XCTAssertTrue(deliveryCompletionCalled)
        let receivedRequest = delegate.receivedOverrideRequests.first!
        XCTAssert(updatedActiveOverride.name == receivedRequest.overrideName)
        XCTAssert(updatedActiveOverride.duration == receivedRequest.durationTime)
    }
    
    func testDeliver_WhenInvalid_Fails() async throws {
        
        //Arrange
        
        let presets = [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
        let initialActiveOverride = presets[0]
        let overrideState = OverrideState(activeOverride: initialActiveOverride, presets: presets)
        let deliveryError = OverrideViewDelegateMock.MockError.NetworkError
        let delegate = OverrideViewDelegateMock(mockState: .overrideState(overrideState), mockDeliveryError: deliveryError)
        let viewModel = OverrideViewModel()
        
        //Act
        
        var deliveryCompletionCalled = false
        await viewModel.setup(delegate: delegate, deliveryCompleted: {deliveryCompletionCalled = true})
        let updatedActiveOverride = presets[1]
        viewModel.pickerSelectedRow = OverridePickerRowModel(preset: presets[1], activeOverride: updatedActiveOverride)
        await viewModel.updateButtonTapped()
        
        //Assert
        let receivedRequest = delegate.receivedOverrideRequests.first!
        XCTAssert(updatedActiveOverride.name == receivedRequest.overrideName)
        XCTAssert(updatedActiveOverride.duration == receivedRequest.durationTime)
        XCTAssertFalse(deliveryCompletionCalled)
        XCTAssertEqual(deliveryError.localizedDescription, viewModel.lastDeliveryError?.localizedDescription)
        
    }



}

class OverrideViewDelegateMock: OverrideViewDelegate {
    
    var receivedOverrideRequests = [(overrideName: String, durationTime: TimeInterval)]()
    var mockOverrideState: MockOverrideStateResponse
    var mockDeliveryError: Error? = nil
    
    internal init(receivedOverrideRequests: [(overrideName: String, durationTime: TimeInterval)] = [(overrideName: String, durationTime: TimeInterval)](), mockState: OverrideViewDelegateMock.MockOverrideStateResponse, mockDeliveryError: Error? = nil) {
        self.receivedOverrideRequests = receivedOverrideRequests
        self.mockOverrideState = mockState
        self.mockDeliveryError = mockDeliveryError
    }
    
    func overrideState() async throws -> OverrideState {
        switch mockOverrideState {
        case .error(let error):
            throw error
        case .overrideState(let state):
            return state
        }
    }
    
    func startOverride(overrideName: String, durationTime: TimeInterval) async throws {
        //throw OverrideViewPreviewMockError.NetworkError //Testing
        //guard let preset = presets.first(where: {$0.name == overrideName}) else {return}
        receivedOverrideRequests.append((overrideName: overrideName, durationTime: durationTime))
        if let mockDeliveryError {
            throw mockDeliveryError
        }
    }
    
    func cancelOverride() async throws {
        
    }
    
    static var mockOverrides: [NightscoutKit.TemporaryScheduleOverride] {
        return [
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏃", name: "Running"),
            TemporaryScheduleOverride(duration: 60.0, targetRange: nil, insulinNeedsScaleFactor: nil, symbol: "🏊", name: "Swimming")
        ]
    }
    
    enum MockError: LocalizedError {
        case NetworkError
        
        var errorDescription: String? {
            switch self {
            case .NetworkError:
                return "Connect to the network"
            }
        }
    }
    
    enum MockOverrideStateResponse {
        case error(Error)
        case overrideState(OverrideState)
    }
}
