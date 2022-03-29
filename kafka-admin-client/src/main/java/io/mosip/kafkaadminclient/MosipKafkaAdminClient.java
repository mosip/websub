package io.mosip.kafkaadminclient;

import java.util.Collections;
import java.util.Optional;
import java.util.Properties;

import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.KafkaFuture;
import org.apache.kafka.common.errors.TopicExistsException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MosipKafkaAdminClient {

	private static final Logger LOGGER = LoggerFactory.getLogger(MosipKafkaAdminClient.class);

	private Properties properties;

	public MosipKafkaAdminClient(String bootstrapServers) {
		properties = new Properties();
		properties.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);

	}

	public void createTopic(String topicName) throws Exception {
		try (Admin admin = Admin.create(properties)) {
			NewTopic newTopic = new NewTopic(topicName, Optional.of(1), Optional.empty());
			CreateTopicsResult result = admin.createTopics(Collections.singleton(newTopic));
			// get the async result for the new topic creation
			KafkaFuture<Void> future = result.values().get(topicName);
			// call get() to block until topic creation has completed or failed
				future.get();
		}
	}
}
