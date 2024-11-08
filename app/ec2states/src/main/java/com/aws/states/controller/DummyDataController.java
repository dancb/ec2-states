package com.aws.states.controller;

import com.aws.states.model.DummyData;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Named;
import java.util.ArrayList;
import java.util.List;

@Named
@RequestScoped
public class DummyDataController {

    private List<DummyData> dummyDataList;

    // Constructor que inicializa los datos
    public DummyDataController() {
        dummyDataList = new ArrayList<>();
        for (int i = 1; i <= 10; i++) {
            dummyDataList.add(new DummyData("Data1_" + i, "Data2_" + i, "Data3_" + i, "Data4_" + i, "Data5_" + i));
        }
    }

    public List<DummyData> getDummyDataList() {
        return dummyDataList;
    }
}
